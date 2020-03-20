# frozen_string_literal: true

module PackageManager
  class Homebrew < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_PLANNED = true
    SECURITY_PLANNED = false
    URL = "http://brew.sh/"
    COLOR = "#555555"

    def self.package_link(project, _version = nil)
      "http://formulae.brew.sh/formula/#{project.name}"
    end

    def self.install_instructions(project, _version = nil)
      "brew install #{project.name}"
    end

    def self.project_names
      get("https://formulae.brew.sh/api/formula.json").map { |project| project["name"] }.uniq
    end

    def self.recent_names
      rss = SimpleRSS.parse(get_raw("http://formulae.brew.sh/feed.atom"))
      rss.entries.map { |entry| entry.link.split("/")[-1] }.map { |e| e.split("@").first }.uniq
    end

    def self.project(name)
      get("https://formulae.brew.sh/api/formula/#{name}.json")
    end

    def self.mapping(project)
      {
        name: project["formula"],
        description: project["description"],
        homepage: project["homepage"],
        repository_url: repo_fallback("", project["homepage"]),
        version: project["version"],
        dependencies: project["dependencies"],
      }
    end

    def self.versions(project, _name)
      [
        {
          number: project["version"],
        },
      ]
    end

    def self.dependencies(_name, version, project)
      return nil unless version == project[:version]

      project[:dependencies].map do |dependency|
        {
          project_name: dependency,
          requirements: "*",
          kind: "runtime",
          platform: name.demodulize,
        }
      end
    end
  end
end
