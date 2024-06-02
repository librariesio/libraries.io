# frozen_string_literal: true

module PackageManager
  class Meteor < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_SUPPORT = true
    URL = "https://atmospherejs.com"
    COLOR = "#f1e05a"

    def self.package_link(db_project, _version = nil)
      "https://atmospherejs.com/#{db_project.name.tr(':', '/')}"
    end

    def self.install_instructions(db_project, version = nil)
      "meteor add #{db_project.name}" + (version ? "@=#{version}" : "")
    end

    def self.project_names
      projects.keys
    end

    def self.projects
      @projects ||= begin
        projects = {}
        packages = get_json("https://atmospherejs.com/a/packages")

        packages.each do |hash|
          next if hash["latestVersion"].nil?

          projects[hash["name"].downcase] = hash["latestVersion"].merge({ "name" => hash["name"] })
        end

        projects
      end
    end

    def self.project(name)
      projects[name.downcase]
    end

    def self.mapping(raw_project)
      MappingBuilder.build_hash(
        name: raw_project["name"],
        description: raw_project["description"],
        repository_url: repo_fallback(raw_project["git"], nil)
      )
    end

    def self.versions(raw_project, _name)
      [VersionBuilder.build_hash(
        number: raw_project["version"],
        published_at: Time.at(raw_project["published"]["$date"] / 1000.0)
      )]
    end
  end
end
