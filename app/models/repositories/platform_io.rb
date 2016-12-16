module Repositories
  class PlatformIO < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    LIBRARIAN_PLANNED = true
    URL = 'http://platformio.org'
    COLOR = '#f34b7d'

    def self.package_link(name, version = nil)
      "http://platformio.org/lib/show/#{project.pm_id}/#{name}"
    end

    def self.install_instructions(project, version = nil)
      "platformio lib install #{project.pm_id}"
    end

    def self.project_names
      page = 1
      projects = []
      while true
        sleep 1
        r = Repositories::Base.get("http://api.platformio.org/lib/search?page=#{page}")
        break if page > r['total'].to_f/r['perpage'].to_f
        projects += r['items']
        page +=1
      end
      projects.map{|project| project['id'] }.sort.uniq
    end

    def self.project(id)
      sleep 1
      get("http://api.platformio.org/lib/info/#{id}")
    end

    def self.mapping(project)
      {
        :name => project['name'],
        :pm_id => project['id'],
        :homepage => project['url'],
        :description => project['description'],
        :keywords_array => Array.wrap(project["keywords"]),
        :repository_url => repo_fallback('', project['url'])
      }
    end

    def self.versions(project)
      version = project['version']
      [{
        :number => version['name'],
        :published_at => version['released']
      }]
    end
  end
end
