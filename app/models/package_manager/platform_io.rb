# frozen_string_literal: true

module PackageManager
  class PlatformIO < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_PLANNED = true
    URL = "https://platformio.org"
    COLOR = "#f34b7d"

    def self.package_link(project, _version = nil)
      "https://platformio.org/lib/show/#{project.pm_id}/#{project.name}"
    end

    def self.install_instructions(project, _version = nil)
      "platformio lib install #{project.pm_id}"
    end

    def self.project_names
      page = 1
      projects = []
      loop do
        sleep 1
        r = get("https://api.platformio.org/lib/search?page=#{page}")
        break if page > r["total"] / r["perpage"].to_f

        projects += r["items"]
        page += 1
      end
      projects.map { |project| project["id"] }.sort.uniq
    end

    def self.project(name)
      sleep 1
      # PlatformIO only takes its ids for project lookups, so we have to find it first.
      if (db_project = Project.find_by(platform: "PlatformIO", name: name))
        get("https://api.platformio.org/lib/info/#{db_project.pm_id}")
      end
    end

    def self.mapping(raw_project)
      {
        name: raw_project["name"],
        pm_id: raw_project["id"],
        homepage: raw_project["homepage"],
        description: raw_project["description"],
        keywords_array: Array.wrap(raw_project["keywords"]),
        repository_url: repo_fallback("", raw_project["repository"]),
      }
    end

    def self.versions(raw_project, _name)
      version = raw_project["version"]
      return [] if version.nil?

      [{
        number: version["name"],
        published_at: version["released"],
      }]
    end
  end
end
