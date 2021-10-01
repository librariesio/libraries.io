# frozen_string_literal: true

module PackageManager
  class NPM < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    SECURITY_PLANNED = true
    URL = "https://www.npmjs.com"
    COLOR = "#f1e05a"
    ENTIRE_PACKAGE_CAN_BE_DEPRECATED = true
    SUPPORTS_SINGLE_VERSION_UPDATE = true

    def self.package_link(project, _version = nil)
      "https://www.npmjs.com/package/#{project.name}"
    end

    def self.download_url(db_project, version = nil)
      "https://registry.npmjs.org/#{db_project.name}/-/#{db_project.name}-#{version}.tgz"
    end

    def self.install_instructions(project, version = nil)
      "npm install #{project.name}" + (version ? "@#{version}" : "")
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
      get("http://registry.npmjs.org/#{name.gsub('/', '%2F')}")
    end

    def self.deprecation_info(name)
      last_version = project(name)["versions"].values.last

      {
        is_deprecated: !!last_version["deprecated"],
        message: last_version["deprecated"],
      }
    end

    def self.mapping(raw_project)
      return nil unless raw_project["versions"].present?

      latest_version = raw_project["versions"].to_a.last[1]

      repo = latest_version.fetch("repository", {})
      repo = repo[0] if repo.is_a?(Array)
      repo_url = repo.try(:fetch, "url", nil)

      {
        name: raw_project["name"],
        description: latest_version["description"],
        homepage: raw_project["homepage"],
        keywords_array: Array.wrap(latest_version.fetch("keywords", [])),
        licenses: licenses(latest_version),
        repository_url: repo_fallback(repo_url, raw_project["homepage"]),
      }
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
        {
          number: k,
          published_at: raw_project.fetch("time", {}).fetch(k, nil),
          original_license: license,
        }
      end
    end

    def self.one_version(raw_project, version_string)
      versions(raw_project, raw_project["name"])
        .find { |v| v[:number] == version_string }
    end

    def self.dependencies(_name, version, mapped_project)
      vers = mapped_project.fetch(:versions, {})[version]
      return [] if vers.nil?

      map_dependencies(vers.fetch("dependencies", {}), "runtime") +
        map_dependencies(vers.fetch("devDependencies", {}), "Development") +
        map_dependencies(vers.fetch("optionalDependencies", {}), "Optional", true)
    end
  end
end
