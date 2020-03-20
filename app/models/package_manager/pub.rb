# frozen_string_literal: true

module PackageManager
  class Pub < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    URL = "https://pub.dartlang.org"
    COLOR = "#00B4AB"

    def self.package_link(project, _version = nil)
      "https://pub.dartlang.org/packages/#{project.name}"
    end

    def self.download_url(name, version = nil)
      "https://storage.googleapis.com/pub.dartlang.org/packages/#{name}-#{version}.tar.gz"
    end

    def self.documentation_url(name, version = nil)
      "http://www.dartdocs.org/documentation/#{name}/#{version}"
    end

    def self.project_names
      page = 1
      projects = []
      loop do
        r = get("https://pub.dartlang.org/api/packages?page=#{page}")
        break if r["packages"] == []

        projects += r["packages"]
        page += 1
      end
      projects.map { |project| project["name"] }.sort
    end

    def self.recent_names
      get("https://pub.dartlang.org/api/packages?page=1")["packages"].map { |project| project["name"] }
    end

    def self.project(name)
      get("https://pub.dartlang.org/api/packages/#{name}")
    end

    def self.mapping(project)
      latest_version = project["versions"].last
      {
        name: project["name"],
        homepage: latest_version["pubspec"]["homepage"],
        description: latest_version["pubspec"]["description"],
        repository_url: repo_fallback("", latest_version["pubspec"]["homepage"]),
        versions: project["versions"],
      }
    end

    def self.versions(project, _name)
      project["versions"].map do |v|
        {
          number: v["version"],
        }
      end
    end

    def self.dependencies(_name, version, project)
      vers = project[:versions].find { |v| v["version"] == version }
      return [] if vers.nil?

      map_dependencies(vers["pubspec"].fetch("dependencies", {}), "runtime") +
        map_dependencies(vers["pubspec"].fetch("dev_dependencies", {}), "Development")
    end
  end
end
