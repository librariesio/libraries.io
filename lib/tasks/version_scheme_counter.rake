# frozen_string_literal: true
#
# [
#   ["Maven", "io.redlink.geocoding:proxy-commons"],
#   ["Packagist", "phraseanet/php-sdk"]
# ].each { |project| PackageManager.const_get(project[0]).update project[1]}
#
#
# Version scheme detection methodology:
# 1. Test against all schemes and keep a tally of which ones validate.
# 2. The scheme which tested positive for all versions is the detected scheme.
# 3. In the case of a tie:
#     1. Since calver validates as other schemes, prefer calver since it is unusual and likely calver.
#     2. If Semver is one of the contenders, prefer Semver for its ubiquity.
#     3. Assume only a Maven project would use the Maven or OSGi versioning schemes.
#
# Known issues: many version schemes will match PEP440 and even Maven and yet be Semver. In the case of a tie, we choose
#   semver, but this may turn out to be the wrong choice later on.
#
# Note: Maven versioning scheme is a looser form of OSGi

module VersionSchemeDetection
  REGEXES = {
    # Based on https://docs.oracle.com/middleware/1212/core/MAVEN/maven_version.htm#MAVEN8855
    # Derived from https://github.com/mojohaus/build-helper-maven-plugin/blob/master/src/main/java/org/codehaus/mojo/buildhelper/versioning/VersionInformation.java
    MAVEN: /^\d+(\.\d+)?{1,2}(.*)$/,
    # OSGI versioning can be expected primarily on Maven projects.
    # Derived from http://docs.osgi.org/specification/osgi.core/7.0.0/framework.module.html#i2655136
    OSGI: /^\d+(\.\d+)?{1,2}(\.[a-zA-Z0-9_-]+)?$/,
    # PEP440 Regex copied from https://www.python.org/dev/peps/pep-0440/#appendix-b-parsing-version-strings-with-regular-expressions
    PEP440: /^([1-9][0-9]*!)?(0|[1-9][0-9]*)(\.(0|[1-9][0-9]*))*((a|b|rc)(0|[1-9][0-9]*))?(\.post(0|[1-9][0-9]*))?(\.dev(0|[1-9][0-9]*))?$/
  }

  # validators return truthy/falsy
  VALIDATORS = {
    MAVEN: ->(version) { version =~ REGEXES[:MAVEN] },
    PEP440: ->(version) { version =~ REGEXES[:PEP440] },
    OSGI: ->(version) { version =~ REGEXES[:OSGI] },
    SEMVER: ->(version) { SemanticRange.valid(version).present? },
    CALVER: lambda do |version|
      first_part = version.split(".")[0]
      # Assume most if not all Calver versions were released after 1000 AD
      # Also assume if they are using YY as the first part that it is after 2000 AD
      first_part.length >= 4 || (first_part.length == 2 && first_part.to_i > 0)
    end
  }

  TALLIES = { semver: 0, pep440: 0, maven: 0, osgi: 0, calver: 0, unknown: 0, no_versions: 0, cursor: 0 }.freeze

  def self.build_project_where_clause(packages)
    project_table = Project.arel_table

    packages.reduce(Arel::Nodes::False.new) do |clause, package|
      clause.or(
        project_table.grouping(
          project_table.lower(project_table[:platform]).eq(package[0].downcase).and(
            project_table[:name].eq(package[1])
          )
        )
      )
    end
  end
end

namespace :version do
  desc 'Tests a sampling of project\'s versions to count occurrences of different versioning schemes'
  task :scheme_counter, [:package_list, :output_file] => :environment do |t, args|
    raise "Provide package_list csv file with columns [package_platform, package_name]" unless args[:package_list].present?

    output_file = args[:output_file] || File.join(__dir__, "output", "version_scheme_count.json")

    global_tallies = VersionSchemeDetection::TALLIES.clone(freeze: false)
    warnings = []
    versionless_packages = []
    unknown_schemes = []

    packages = CSV.read(args[:package_list])

    previous_tallies = File.exist?(output_file) && File.read(output_file)
    if previous_tallies.present?
      global_tallies = JSON.parse(previous_tallies, symbolize_names: true)
      packages = packages[global_tallies[:cursor]..]
    end

    slice_size = 1000

    packages&.each_slice(slice_size) do |packages_slice|
      Project
        .includes(:versions)
        .where(VersionSchemeDetection.build_project_where_clause(packages_slice)).limit(slice_size).each do |project|
        project_platform = project.platform
        project_name = project.name

        local_tallies = VersionSchemeDetection::TALLIES.clone(freeze: false)

        unless project.versions_count?
          global_tallies[:no_versions] += 1
          versionless_packages.push([project_platform, project_name])
          next
        end

        project.versions.each do |version|
          version_number = version.number
          matchable = false
          [
            :semver,
            :pep440,
            :calver,
            *([:maven, :osgi] if project_platform.downcase == "maven"),
          ].each do |scheme|
            if VersionSchemeDetection::VALIDATORS[scheme.upcase].call(version_number)
              local_tallies[scheme] += 1
              matchable = true
            end
          end

          if !matchable
            local_tallies[:unknown] += 1
          end
        end

        max_count = local_tallies.values.max
        maxes = local_tallies.select { |_, tally| tally == max_count }.keys

        # If there are no schemes which matched all versions, consider the scheme unknown.
        if max_count != project.versions_count
          detected_scheme = :unknown
        elsif maxes.length == 1
          detected_scheme = maxes[0]
        elsif maxes.include?(:calver)
          detected_scheme = :calver
        elsif maxes.include?(:semver)
          detected_scheme = :semver
        elsif (maxes & [:maven, :osgi]).any? && project_platform.downcase == "maven"
          detected_scheme = maxes.include?(:osgi) ? :osgi : :maven
        elsif maxes.include?(:pep440)
          detected_scheme = :pep440
        else
          warnings.push("#{project_platform}:#{project_name} has #{maxes} but couldn't determine which to choose so picked #{maxes[0]}")
          detected_scheme = maxes[0]
        end

        unknown_schemes.push([project_platform, project_name, project.versions.map(&:number)]) if detected_scheme == :unknown

        global_tallies[detected_scheme] += 1
      end

      global_tallies[:cursor] = global_tallies[:cursor] + packages_slice.length

      File.write(
        output_file,
        JSON.pretty_generate(
          {
            **global_tallies,
            unknown_schemes: unknown_schemes,
            warnings: warnings,
            versionless_packages: versionless_packages
          }
        )
      )
    end
  end
end
