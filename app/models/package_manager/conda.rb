# frozen_string_literal: true

module PackageManager
  class Conda < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    URL = "https://anaconda.org"

    def self.formatted_name
      "conda"
    end

    def self.project_names
      get_json("https://conda.libraries.io/packages").flat_map { |name| name.split("/").last }
    end

    def self.recent_names
      get_json("https://conda.libraries.io/feed.json")
    end

    def self.package_link(project, _version = nil)
      "https://anaconda.org/anaconda/#{project.name}"
    end

    def self.install_instructions(project, _version = nil)
      "conda install -c anaconda #{project.name}"
    end

    def self.project(name)
      get_json("https://conda.libraries.io/package?name=#{name}")
    end

    def self.check_status_url(project)
      "https://conda-parser.libraries.io/package?name=#{project.name}"
    end

    def self.mapping(project)
      {
        name: project["name"],
        description: project["description"],
        homepage: project["home"],
        keywords_array: Array.wrap(project.fetch("keywords", [])),
        licenses: project["license"],
        repository_url: project["dev_url"],
        versions: [project["version"]],
      }
    end

    def self.versions(project, _name)
      [{ number: project["version"], published_at: Time.at(project["timestamp"]) }]
    end

    def self.dependencies(name, version, _project)
      version_data = get_json("https://conda-parser.libraries.io/package?name=#{name}&version=#{version}")
      deps = version_data["depends"].map { |d| d.split(" ") }
      map_dependencies(deps, "runtime")
    end
  end
end
