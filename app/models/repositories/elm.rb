module Repositories
  class Elm < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    LIBRARIAN_SUPPORT = true
    URL = 'http://package.elm-lang.org/'
    COLOR = '#60B5CC'

    def self.project_names
      projects.keys
    end

    def self.projects
      @projects ||= begin
        prjs = {}
        get('http://package.elm-lang.org/all-packages').each do |prj|
          prjs[prj['name']] = prj
        end
        prjs
      end
    end

    def self.project(name)
      projects[name]
    end

    def self.mapping(project)
      {
        :name => project["name"],
        :description => project["summary"],
        :repository_url => "https://github.com/#{project["name"]}"
      }
    end

    def self.versions(project)
      project['versions'].map do |v|
        { :number => v }
      end
    end
  end
end
