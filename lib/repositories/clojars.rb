class Repositories
  class Clojars < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = true
    URL = 'https://clojars.org'
    COLOR = '#db5855'

    def self.project_names
      projects.keys
    end

    def self.projects
      @projects ||= get("http://clojars-json.herokuapp.com/feed.json")
    end

    def self.versions
      @versions ||= get("http://clojars-json.herokuapp.com/packages.json")
    end

    def self.project(name)
      projects[name.downcase].try(:first).merge(name: name)
    end

    def self.mapping(project)
      {
        :name => project["name"],
        :description => project["description"],
        :repository_url => repo_fallback(project["scm"]["url"], '')
      }
    end

    def self.versions(project)
      []
    end
  end
end
