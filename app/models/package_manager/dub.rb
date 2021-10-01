# frozen_string_literal: true

module PackageManager
  class Dub < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    URL = "http://code.dlang.org"
    COLOR = "#ba595e"

    def self.package_link(db_project, version = nil)
      "http://code.dlang.org/packages/#{db_project.name}" + (version ? "/#{version}" : "")
    end

    def self.install_instructions(db_project, version = nil)
      "dub fetch #{db_project.name}" + (version ? " --version #{version}" : "")
    end

    def self.project_names
      get("http://code.dlang.org/packages/index.json").sort
    end

    def self.project(name)
      get("http://code.dlang.org/packages/#{name}.json")
    end

    def self.mapping(raw_project)
      latest_version = raw_project["versions"].last
      {
        name: raw_project["name"],
        description: latest_version["description"],
        homepage: latest_version["homepage"],
        keywords_array: format_keywords(raw_project["categories"]),
        licenses: latest_version["license"],
        repository_url: repo_fallback(repository(raw_project["repository"]), latest_version["homepage"]),
      }
    end

    def self.versions(raw_project, _name)
      acceptable_versions(raw_project).map do |v|
        {
          number: v["version"],
          published_at: v["date"],
        }
      end
    end

    def self.acceptable_versions(project)
      project["versions"].select do |version|
        (version["version"] =~ /^~.*/i).nil?
      end
    end

    def self.repository(hash)
      if hash["kind"] == "github"
        "https://github.com/#{hash['owner']}/#{hash['project']}"
      elsif hash["kind"] == "bitbucket"
        "https://bitbucket.org/#{hash['owner']}/#{hash['project']}"
      else
        ""
      end
    end

    def self.format_keywords(categories)
      Array.wrap(categories).join(".").split(".").map(&:downcase).uniq
    end

    def self.dependencies(_name, version, mapped_project)
      vers = mapped_project[:versions].find { |v| v["version"] == version }
      return [] if vers.nil?

      deps = vers["dependencies"]
      return [] if deps.nil?

      deps.map do |k, v|
        if v.is_a? Hash
          req = v["version"]
          optional = v["optional"]
        else
          req = v
          optional = false
        end
        {
          project_name: k,
          requirements: req,
          kind: "runtime",
          optional: optional,
          platform: name.demodulize,
        }
      end
    end
  end
end
