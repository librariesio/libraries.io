# frozen_string_literal: true

module PackageManager
  class PlatformIO < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_PLANNED = true
    URL = "http://platformio.org"
    COLOR = "#f34b7d"

    def self.package_link(project, _version = nil)
      "http://platformio.org/lib/show/#{project.pm_id}/#{project.name}"
    end

    def self.install_instructions(project, _version = nil)
      "platformio lib install #{project.pm_id}"
    end

    def self.project_names
      page = 1
      projects = []
      loop do
        sleep 1
        r = PackageManager::Base.get("http://api.platformio.org/lib/search?page=#{page}")
        break if page > r["total"].to_f / r["perpage"].to_f

        projects += r["items"]
        page += 1
      end
      projects.map { |project| project["id"] }.sort.uniq
    end

    def self.project(id)
      sleep 1
      get("http://api.platformio.org/lib/info/#{id}")
    end

    def self.mapping(project)
      {
        name: project["name"],
        pm_id: project["id"],
        homepage: project["homepage"],
        description: project["description"],
        keywords_array: Array.wrap(project["keywords"]),
        repository_url: repo_fallback("", project["repository"]),
      }
    end

    def self.versions(project)
      version = project["version"]
      return [] if version.nil?

      [{
        number: version["name"],
        published_at: version["released"],
      }]
    end
  end
end
