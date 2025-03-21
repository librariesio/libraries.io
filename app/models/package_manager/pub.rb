# frozen_string_literal: true

module PackageManager
  class Pub < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    URL = "https://pub.dartlang.org"
    COLOR = "#00B4AB"

    def self.package_link(db_project, _version = nil)
      "https://pub.dartlang.org/packages/#{db_project.name}"
    end

    def self.download_url(db_project, version = nil)
      "https://storage.googleapis.com/pub.dartlang.org/packages/#{db_project.name}-#{version}.tar.gz"
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

    def self.mapping(raw_project)
      latest_version = raw_project["versions"].last
      MappingBuilder.build_hash(
        name: raw_project["name"],
        homepage: latest_version["pubspec"]["homepage"],
        description: latest_version["pubspec"]["description"],
        repository_url: repo_fallback("", latest_version["pubspec"]["homepage"]),
        versions: raw_project["versions"]
      )
    end

    def self.versions(raw_project, _name)
      raw_project["versions"].map do |v|
        VersionBuilder.build_hash(
          number: v["version"]
        )
      end
    end

    def self.dependencies(_name, version, mapped_project)
      vers = mapped_project[:versions].find { |v| v["version"] == version }
      return [] if vers.nil?

      deps = map_dependencies(vers.dig("pubspec", "dependencies" || []), "runtime") +
             map_dependencies(vers.dig("pubspec", "dev_dependencies") || [], "Development")

      deps.each do |d|
        # "dependencies" items can be a String, or a Hash with more details
        d[:requirements] = d[:requirements]["version"] if d[:requirements].is_a?(Hash)

        # "any" means any version, and it is assumed when the version is blank.
        # https://dart.dev/tools/pub/dependencies#hosted-packages
        d[:requirements] = "*" if d[:requirements].blank? || d[:requirements] == "any"
      end

      deps
    end
  end
end
