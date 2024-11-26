# frozen_string_literal: true

module PackageManager
  class NPM < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    URL = "https://www.npmjs.com"
    COLOR = "#f1e05a"
    ENTIRE_PACKAGE_CAN_BE_DEPRECATED = true

    def self.missing_version_remover
      PackageManager::Base::MissingVersionRemover
    end

    def self.package_link(db_project, _version = nil)
      "https://www.npmjs.com/package/#{db_project.name}"
    end

    def self.download_url(db_project, version = nil)
      "https://registry.npmjs.org/#{db_project.name}/-/#{db_project.name}-#{version}.tgz"
    end

    def self.check_status_url(db_project)
      "https://registry.npmjs.org/#{db_project.name.gsub('/', '%2F')}"
    end

    def self.install_instructions(db_project, version = nil)
      "npm install #{db_project.name}" + (version ? "@#{version}" : "")
    end

    def self.formatted_name
      "npm"
    end

    def self.project_names
      get("https://raw.githubusercontent.com/nice-registry/all-the-package-names/master/names.json")
    end

    def self.recent_names
      u = "http://registry.npmjs.org/-/rss?descending=true&limit=50"
      SimpleRSS.parse(get_raw(u)).items.map(&:title).uniq
    end

    def self.project(name)
      get("https://registry.npmjs.org/#{name.gsub('/', '%2F')}")
    end

    def self.deprecation_info(db_project)
      # NPM only allows versions to be deprecated (not the whole package), so we count a package deprecated
      # on NPM if the latest version is deprecated (vs requiring all versions to be deprecated), because
      # the package page will say it's deprecated if even the latest version is actually deprecated.
      versions = project(db_project.name)&.dig("versions")&.values || []
      last_stable_version = versions
        # Ignore prerelease versions as some packages will regularly push prereleases and mark them deprecated, e.g. graphql.
        .reject do |v|
          Semantic::Version.new(v["version"]).pre.present?
      rescue StandardError
        false
        end
        .last

      message = last_stable_version&.dig("deprecated")
      # sometimes message is a boolean `false`, and it may be `true` sometimes (not sure but
      # may as well handle it, apparently we return any type we like)
      if message.nil?
        is_deprecated = false
      elsif [true, false].include?(message)
        is_deprecated = message
        message = nil
      elsif message.is_a? String
        is_deprecated = true
      else
        is_deprecated = false
      end

      {
        is_deprecated: is_deprecated,
        message: message,
      }
    end

    def self.mapping(raw_project)
      latest_version = if raw_project["versions"].present?
                         raw_project["versions"].to_a.last[1]
                       else
                         {} # "Removed" projects won't have a "versions" Hash
                       end

      repo = raw_project.fetch("repository", {}).presence || latest_version.fetch("repository", {})
      repo = repo[0] if repo.is_a?(Array)
      repo_url = repo.try(:fetch, "url", nil)

      MappingBuilder.build_hash(
        name: raw_project["name"],
        description: latest_version["description"],
        homepage: raw_project["homepage"],
        keywords_array: Array.wrap(latest_version.fetch("keywords", [])),
        licenses: licenses(latest_version),
        repository_url: repo_fallback(repo_url, raw_project["homepage"]),
        versions: raw_project.fetch("versions", {})
      )
    end

    def self.licenses(latest_version)
      license = latest_version.fetch("license", nil)
      if license.present?
        if license.is_a?(Hash)
          license.fetch("type", "")
        else
          license
        end
      else
        licenses = Array(latest_version.fetch("licenses", []))
        licenses.map do |lice|
          if lice.is_a?(Hash)
            lice.fetch("type", "")
          else
            lice
          end
        end.join(",")
      end
    end

    def self.versions(raw_project, _name)
      # npm license fields are supposed to be SPDX expressions now https://docs.npmjs.com/files/package.json#license
      return [] if raw_project.nil?

      raw_project.fetch("versions", {}).map do |k, v|
        license = v.fetch("license", nil)
        license = licenses(v) unless license.is_a?(String)
        license = "" if license.nil?
        VersionBuilder.build_hash(
          number: k,
          published_at: raw_project.fetch("time", {}).fetch(k, nil),
          original_license: license
        )
      end
    end

    # NPM is currently unreliable in its update publishing.
    # The updates are coming in out of order, which is throwing off single version updates.
    # See https://github.com/librariesio/libraries.io/pull/3278 for more details.
    def self.supports_single_version_update?
      false
    end

    def self.one_version(raw_project, version_string)
      versions(raw_project, raw_project["name"])
        .find { |v| v[:number] == version_string }
    end

    def self.dependencies(name, version, mapped_project)
      vers = mapped_project.fetch(:versions, {})[version]
      if vers.nil?
        StructuredLog.capture("DEPENDENCIES_FAILURE", { platform: db_platform, name: name, version: version, message: "version not found in upstream" })
        return []
      end

      deps = map_dependencies(vers.fetch("dependencies", {}), "runtime") +
             map_dependencies(vers.fetch("devDependencies", {}), "Development") +
             map_dependencies(vers.fetch("optionalDependencies", {}), "Optional", optional: true)

      deps.each do |d|
        # Via https://docs.npmjs.com/cli/v9/configuring-npm/package-json#dependencies:
        #   `"" (just an empty string) Same as *`
        d[:requirements] = "*" if d[:requirements].blank?
      end

      deps
    end
  end
end
