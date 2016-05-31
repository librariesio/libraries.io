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
        data = get("https://bower.herokuapp.com/packages")

        data.each do |hash|
          projects[hash['name'].downcase] = hash.slice('name', 'url')
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
        :repository_url => repo_fallback(nil, project["url"])
      }
    end
  end
end
