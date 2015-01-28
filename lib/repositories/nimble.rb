class Repositories
  class Nimble < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    URL = 'https://github.com/nim-lang/nimble'

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

    def self.mapping(project)
      {
        :name => project["name"],
        :description => project["description"],
        :repository_url => project['url'],
        :keywords => project['tags'].join(','),
        :licenses => project['license'],
        :homepage => project['web']
      }
    end
  end
end
