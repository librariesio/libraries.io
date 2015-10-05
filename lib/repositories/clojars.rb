class Repositories
  class Clojars < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    LIBRARIAN_SUPPORT = true
    URL = 'https://clojars.org'
    COLOR = '#db5855'

    def self.project_names
      @names ||= get("http://clojars-json.herokuapp.com/packages.json").keys
    end

    def self.projects
      @projects ||= get("http://clojars-json.herokuapp.com/feed.json")
    end

    def self.project(name)
      projects[name.downcase].try(:first).merge(name: name)
    end

    def self.mapping(project)
      name = project[:name] == project["group-id"] ? project[:name] : "#{project["group-id"]}/#{project[:name]}"
      {
        :name => name,
        :description => project["description"],
        :repository_url => repo_fallback(project["scm"]["url"], '')
      }
    end

    def self.versions(project)
      project['versions'].map do |v|
        {
          :number => v['version']
        }
      end
    end
  end
end
