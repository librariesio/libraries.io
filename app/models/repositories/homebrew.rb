module Repositories
  class Homebrew < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    LIBRARIAN_PLANNED = true
    SECURITY_PLANNED = false
    URL = 'http://brew.sh/'
    COLOR = '#a1804c'

    def self.project_names
      page = 1
      projects = []
      while true
        r = get("http://brewformulas.org/?format=json&page=#{page}")['formulas']
        break if  r == []
        projects += r
        page +=1
      end
      projects.map{|project| project['formula'] }.uniq
    end

    def self.recent_names
      page = 1
      projects = []
      while true
        r = get("http://brewformulas.org/?format=json&page=#{page}")['new_formulas']
        break if  r == []
        projects += r
        page +=1
      end
      projects.map{|project| project['formula'] }.uniq
    end

    def self.project(name)
      get("http://brewformulas.org/#{name}.json")
    end

    def self.mapping(project)
      {
        :name => project['formula'],
        :description => project['description'],
        :homepage => project['homepage'],
        :repository_url => repo_fallback('', project['homepage'])
      }
    end
  end
end
