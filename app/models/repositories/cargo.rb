module Repositories
  class Cargo < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    LIBRARIAN_SUPPORT = true
    URL = 'https://crates.io'
    COLOR = '#dea584'

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
        :keywords_array => Array.wrap(project['crate']['keywords']),
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

    def self.dependencies(name, version)
      deps = get("https://crates.io/api/v1/crates/#{name}/#{version}/dependencies")['dependencies']
      return [] if deps.nil?
      deps.map do |dep|
        {
          project_name: dep['crate_id'],
          requirements: dep['req'],
          kind: dep['kind'],
          optional: dep['optional'],
          platform: self.name.demodulize
        }
      end
    end
  end
end
