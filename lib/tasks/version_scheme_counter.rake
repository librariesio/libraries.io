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
# 2. The one with the highest tally is likely the scheme which was being followed.
# 3. If tied for unknown, mark unknown.
# 4. Since calver validates as other schemes, prefer calver in the case of a tie since it is unusual and likely calver.
# 5. In the case of a tie, if Semver is one of the contenders, prefer Semver for its ubiquity.
# 6. Assume only a Maven project would use the Maven or OSGi versioning schemes.
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
    PACKAGIST_SEMVER: ->(version) { version =~ REGEXES[:PACKAGIST_SEMVER] },
    CALVER: lambda do |version|
      first_part = version.split(".")[0]
      # Assume most if not all Calver versions were released after 1000 AD
      # Also assume if they are using YY as the first part that it is after 2000 AD
      first_part.length >= 4 || (first_part.length == 2 && first_part.to_i > 0)
    end
  }

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

tallies = { semver: 0, pep440: 0, maven: 0, osgi: 0, calver: 0, unknown: 0, no_versions: 0 }

def update_output_file(tallies, unknown_schemes, warnings, versionless_packages)
  File.write(File.join(__dir__, "output", "version_scheme_count.json"), JSON.pretty_generate({
                                                                                               **tallies,
                                                                                               unknown_schemes: unknown_schemes,
                                                                                               warnings: warnings,
                                                                                               versionless_packages: versionless_packages
                                                                                             }))
end

namespace :version do
  desc 'Tests a sampling of project\'s versions to count occurrences of different versioning schemes'
  task :scheme_counter, [:package_list] => :environment do |t, args|
    raise "Provide package_list csv file with columns [package_platform, package_name]" unless args[:package_list].present?

    global_tallies = tallies.clone
    warnings = []
    versionless_packages = []
    unknown_schemes = []

    packages = CSV.read(args[:package_list])

    packages.each_slice(1000) do |packages_slice|
      Project
        .includes(:versions)
        .where(VersionSchemeDetection.build_project_where_clause(packages_slice)).limit(1000).each do |project|
        project_platform = project.platform
        project_name = project.name

        local_tallies = tallies.clone

        unless project.versions_count?
          global_tallies[:no_versions] += 1
          puts "#{project_platform}:#{project_name} has no versions."
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
        maxes = local_tallies.select{|_, tally| tally == max_count}.keys

        if maxes.length == 1
          detected_scheme = maxes[0]
        elsif maxes.include?(:unknown)
          detected_scheme = :unknown
        elsif maxes.include?(:semver)
          detected_scheme = :semver
        elsif maxes.include?(:calver)
          detected_scheme = :calver
        elsif (maxes & [:maven, :osgi]).any? && project_platform.downcase == "maven"
          detected_scheme = maxes.include?(:osgi) ? :osgi : :maven
        elsif maxes.include?(:pep440)
          detected_scheme = :pep440
        else
          warning = "#{project_platform}:#{project_name} has #{maxes} but couldn't determine which to choose so picked #{maxes[0]}"
          puts warning
          warnings.push(warning)
          detected_scheme = maxes[0]
        end

        unknown_schemes.push([project_platform, project_name, project.versions.map(&:number)]) if detected_scheme == :unknown

        global_tallies[detected_scheme] += 1
      end

      puts "Running tallies: #{global_tallies}"
      update_output_file(global_tallies, unknown_schemes, warnings, versionless_packages)
    end

    update_output_file(global_tallies, unknown_schemes, warnings, versionless_packages)
  end
end
