module PackageManager
  class Conda < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    URL = "https://anaconda.org"

    def self.formatted_name
      'conda'
    end

    def self.project_names
      # TODO figure out how to support multiple channels from here
      get_json("http://conda.libraries.io/packages").flat_map{|name| name.split("/").last}
    end

    def self.package_link(project, _version = nil)
      "https://anaconda.org/anaconda/#{project.name}"
    end

    def self.install_instructions(project, version = nil)
      "conda install -c anaconda #{project.name}"
    end

    def self.project(name)
      latest_version = get_json("http://conda.libraries.io/package?name=#{name}")
      latest_version[:name] = name

      latest_version
    end

    def self.mapping(project)
      {
        :name => project[:name],
        :description => project["description"],
        :homepage => project["home"],
        :keywords_array => Array.wrap(project.fetch("keywords", [])),
        :licenses => project["license"],
        :repository_url => project["dev_url"],
        :versions => [{ version: project["version"], timestamp: project["timestamp"] }]
      }
    end

    def self.versions(project)
      [{ number: project["version"], published_at: project["timestamp"] }]
    end

    def self.dependencies(name, version, project)
      version_data = get_json("http://conda-parser.libraries.io/package?name=#{name}&version=#{version}")
      deps = version_data["depends"].map { |d| d.split(" ") }
      map_dependencies(deps, "runtime")
    end
  end
end