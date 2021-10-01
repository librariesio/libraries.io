# frozen_string_literal: true
module PackageManager
  class Nimble < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_PLANNED = true
    URL = 'https://github.com/nim-lang/nimble'
    COLOR = '#37775b'

    def self.install_instructions(db_project, version = nil)
      "nimble install #{db_project.name}" + (version ? "@##{version}" : "")
    end

    def self.project_names
      projects.keys.sort
    end

    def self.projects
      @projects ||= begin
        prjcts = {}
        packages = get("https://raw.githubusercontent.com/nim-lang/packages/master/packages.json")
        packages.each do |hash|
          prjcts[hash['name'].downcase] = hash.slice('name', 'url', 'description', 'tags', 'license', 'web')
        end
        prjcts
      end
    end

    def self.project(name)
      projects[name.downcase]
    end

    def self.mapping(raw_project)
      {
        name: raw_project["name"],
        description: raw_project["description"],
        repository_url: repo_fallback(raw_project['url'], raw_project['web']),
        keywords_array: Array.wrap(raw_project["tags"]),
        licenses: raw_project['license'],
        homepage: raw_project['web']
      }
    end
  end
end
