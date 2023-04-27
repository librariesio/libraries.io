# frozen_string_literal: true

module PackageManager
  class CPAN < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    URL = "https://metacpan.org"
    COLOR = "#0298c3"

    def self.package_link(db_project, _version = nil)
      "https://metacpan.org/release/#{db_project.name}"
    end

    def self.project_names
      projects = []
      size = 5000
      time = '1m'
      scroll_start_r = get("https://fastapi.metacpan.org/v1/release/_search?scroll=#{time}&size=#{size}&q=status:latest&fields=distribution")
      projects += scroll_start_r["hits"]["hits"]
      scroll_id = scroll_start_r['_scroll_id']
      loop do
        r = get("https://fastapi.metacpan.org/v1/_search/scroll?scroll=#{time}&scroll_id=#{scroll_id}")
        break if r["hits"]["hits"] == []

        projects += r["hits"]["hits"]
        scroll_id = r['_scroll_id']
      end
      projects.map { |project| project["fields"]["distribution"] }.flatten.uniq
    end

    def self.recent_names
      names = get("https://fastapi.metacpan.org/v1/release/_search?q=status:latest&fields=distribution&sort=date:desc&size=100")["hits"]["hits"]
      names.map { |project| project["fields"]["distribution"] }.uniq
    end

    def self.project(name)
      get("https://fastapi.metacpan.org/v1/release/#{name}")
    end

    def self.mapping(raw_project)
      {
        name: raw_project["distribution"],
        homepage: raw_project.fetch("resources", {})["homepage"],
        description: raw_project["abstract"],
        licenses: raw_project.fetch("license", []).join(","),
        repository_url: repo_fallback(raw_project.fetch("resources", {}).fetch("repository", {})["web"], raw_project.fetch("resources", {})["homepage"]),
        versions: versions(raw_project, raw_project["distribution"]),
      }
    end

    def self.versions(raw_project, _name)
      versions = get("https://fastapi.metacpan.org/v1/release/_search?q=distribution:#{raw_project['distribution']}&size=5000&fields=version,date")["hits"]["hits"]
      versions.map do |version|
        {
          number: version["fields"]["version"],
          published_at: version["fields"]["date"],
        }
      end
    end

    def self.dependencies(_name, version, mapped_project)
      versions = mapped_project[:versions]
      version_data = versions.find { |v| v["fields"]["version"] == version }
      version_data["fields"]["dependency"].select { |dep| dep["relationship"] == "requires" }.map do |dep|
        {
          project_name: dep["module"].gsub("::", "-"),
          requirements: dep["version"],
          kind: dep["phase"],
          platform: name.demodulize,
        }
      end
    end
  end
end
