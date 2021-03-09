# frozen_string_literal: true

module PackageManager
  class Elm < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    URL = "http://package.elm-lang.org/"
    COLOR = "#60B5CC"

    def self.package_link(project, version = nil)
      "http://package.elm-lang.org/packages/#{project.name}/#{version || 'latest'}"
    end

    def self.download_url(name, version = "master")
      "https://github.com/#{name}/archive/#{version}.zip"
    end

    def self.install_instructions(project, version = nil)
      "elm-package install #{project.name} #{version}"
    end

    def self.project_names
      projects.keys
    end

    def self.projects
      @projects ||= get("http://package.elm-lang.org/all-packages")
    end

    def self.recent_names
      get("http://package.elm-lang.org/new-packages")
    end

    def self.project(name)
      get("http://package.elm-lang.org/packages/#{name}/latest/elm.json")
    end

    def self.mapping(project)
      {
        name: project["name"],
        description: project["summary"],
        repository_url: "https://github.com/#{project['name']}",
      }
    end

    def self.versions(_project, name)
      get("https://package.elm-lang.org/packages/#{name}/releases.json")
        .map do |version, timestamp|
          {
            number: version,
            published_at: Time.at(timestamp),
          }
        end
    end

    def self.dependencies(name, version, _mapped_project)
      get("http://package.elm-lang.org/packages/#{name}/#{version}/elm.json")
        .fetch("dependencies", {})
        .map do |name, requirement|
          {
            project_name: name,
            requirements: requirement,
            kind: "runtime",
          }
        end
    end
  end
end
