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
# 6. If a tie between Maven and PEP440, check platform and choose accordingly.
#
# Known issues: many version schemes will match PEP440 and even Maven and yet be Semver. In the case of a tie, we choose
#   semver, but this may turn out to be the wrong choice later on.

module VersionSchemeDetection
  REGEXES = {
    MAVEN: /^(0|([1-9]\d*))(\.[1-9]\d*){1,2}(-(((alpha|beta|rc)-)?\d+|SNAPSHOT))?$/,
    # PEP440 Regex copied from https://www.python.org/dev/peps/pep-0440/#appendix-b-parsing-version-strings-with-regular-expressions
    PEP440: /^([1-9][0-9]*!)?(0|[1-9][0-9]*)(\.(0|[1-9][0-9]*))*((a|b|rc)(0|[1-9][0-9]*))?(\.post(0|[1-9][0-9]*))?(\.dev(0|[1-9][0-9]*))?$/
  }

  # validators return truthy/falsy
  VALIDATORS = {
    MAVEN: ->(version) { version =~ REGEXES[:MAVEN] },
    PEP440: ->(version) { version =~ REGEXES[:PEP440] },
    SEMVER: ->(version) { SemanticRange.valid(version).present? },
    CALVER: lambda do |version|
      first_part = version.split(".")[0]
      # Assume most if not all Calver versions were released after 1000 AD
      # Also assume if they are using YY as the first part that it is after 2000 AD
      first_part.length >= 4 || (first_part.length == 2 && first_part.to_i > 0)
    end
  }
end

tallies = { semver: 0, pep440: 0, maven: 0, calver: 0, unknown: 0, no_versions: 0 }

namespace :version do
  desc 'Tests a sampling of project\'s versions to count occurrences of different versioning schemes'
  task :scheme_counter, [:package_list] => :environment do |t, args|
    raise "Provide package_list csv file with columns [package_platform, package_name]" unless args[:package_list].present?

    global_tallies = tallies.clone.merge({
      unknown_versions: []
    })

    packages = CSV.read(args[:package_list])

    package_platforms, package_names = packages[0].zip(*packages)

    Project.includes(:versions).where(platform: package_platforms, name: package_names).find_each(batch_size: 1000) do |project|
      local_tallies = tallies.clone

      if !project.versions_count?
        global_tallies[:no_versions] += 1
        next
      end

      project.versions.each do |version|
        version_number = version.number
        matchable = false
        [
          :semver,
          :pep440,
          :maven,
          :calver,
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
        global_tallies[:unknown_versions].push([project.platform, project.name, project.versions.pluck(:number)])
        detected_scheme = :unknown
      elsif maxes.include?(:semver)
        detected_scheme = :semver
      elsif maxes.include?(:calver)
        detected_scheme = :calver
      elsif maxes.include?(:maven) && project.platform.downcase == "maven"
        detected_scheme = :maven
      elsif maxes.include?(:pep440) && project.platform.downcase == "pypi"
        detected_scheme = :pep440
      end

      global_tallies[detected_scheme] += 1
    end

    puts global_tallies
    global_tallies[:unknown_versions].each do |unknown|
      puts "unknown scheme for #{unknown[0]}: #{unknown[1]} #{unknown[2]}"
    end if global_tallies[:unknown_versions].length

    File.write(File.join(__dir__, "output", "version_scheme_count.json"), JSON.pretty_generate(global_tallies))
  end
end
