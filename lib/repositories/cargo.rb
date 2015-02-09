class Repositories
  class Cargo < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    URL = 'https://crates.io'

    def self.project_names
      page = 1
      projects = []
      while true
        r = get("https://crates.io/api/v1/crates?page=#{page}&per_page=100")['crates']
        break if r == []
        projects += r
        page +=1
      end
      projects.map{|project| project['name'] }
    end

    def self.project(name)
      get("https://crates.io/api/v1/crates/#{name}")
    end

    def self.mapping(project)
      {
        :name => project['crate']['id'],
        :homepage => project['crate']['homepage'],
        :description => project['crate']['description'],
        :keywords => project['crate']['keywords'].join(','),
        :licenses => project['crate']['license'],
        :repository_url => repo_fallback(project['crate']['repository'], project['crate']['homepage'])
      }
    end

    def self.versions(project)
      project["versions"].map do |version|
        {
          :number => version['num'],
          :published_at => version['created_at']
        }
      end
    end
  end
end
