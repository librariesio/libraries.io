class Repositories
  class CPAN < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    LIBRARIAN_PLANNED = true
    URL = 'https://metacpan.org'
    COLOR = '#0298c3'

    def self.project_names
      page = 1
      projects = []
      while true
        r = get("http://api.metacpan.org/v0/release/_search?q=status:latest&fields=distribution&sort=date:desc&size=5000&from=#{page*5000}")['hits']['hits']
        break if r == []
        projects += r
        page +=1
      end
      projects.map{|project| project['fields']['distribution'] }.uniq
    end

    def self.recent_names
      names = get('http://api.metacpan.org/v0/release/_search?q=status:latest&fields=distribution&sort=date:desc&size=100')['hits']['hits']
      names.map{|project| project['fields']['distribution'] }.uniq
    end

    def self.project(name)
      get("http://api.metacpan.org/v0/release/#{name}")
    end

    def self.mapping(project)
      {
        :name => project['distribution'],
        :homepage => project.fetch('resources',{})['homepage'],
        :description => project['abstract'],
        :licenses => project['license'].join(','),
        :repository_url => repo_fallback(project.fetch('resources',{}).fetch('repository',{})['web'], project.fetch('resources',{})['homepage'])
      }
    end

    def self.versions(project)
      [{
        :number => project['version'],
        :published_at => project['date']
      }]
    end
  end
end
