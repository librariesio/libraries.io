module Repositories
  class Bower < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    LIBRARIAN_SUPPORT = true
    SECURITY_PLANNED = true
    URL = 'http://bower.io'
    COLOR = '#563d7c'

    def self.project_names
      projects.keys
    end

    def self.projects
      @projects ||= begin
        projects = {}
        p1 = get("https://bower-component-list.herokuapp.com")
        p2 = get("https://bower.herokuapp.com/packages")

        p2.each do |hash|
          projects[hash['name'].downcase] = hash.slice('name', 'url', 'hits')
        end

        p1.each do |hash|
          if projects[hash['name'].downcase]
            projects[hash['name'].downcase].merge! hash.slice('description', "owner", "website", "forks", "stars", "created", "updated","keywords")
          end
        end
        projects
      end
    end

    def self.project(name)
      projects[name.downcase]
    end

    def self.mapping(project)
      {
        :name => project["name"],
        :description => project["description"],
        :keywords_array => Array.wrap(project["keywords"]),
        :repository_url => repo_fallback(project["website"], project["url"])
      }
    end
  end
end
