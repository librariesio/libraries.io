module Repositories
  class Atom < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    LIBRARIAN_SUPPORT = true
    SECURITY_PLANNED = true
    URL = 'https://atom.io'
    COLOR = '#244776'

    def self.project_names
      page = 1
      projects = []
      while true
        r = get("https://atom.io/api/packages?page=#{page}")
        break if  r == []
        projects += r
        page +=1
      end
      projects.map{|project| project['name'] }.sort.uniq
    end

    def self.recent_names
      projects = get('https://atom.io/api/packages?page=1&sort=created_at&direction=desc') +
      get('https://atom.io/api/packages?page=1&sort=updated_at&direction=desc')
      projects.map{|project| project['name'] }.uniq
    end

    def self.project(name)
      get("https://atom.io/api/packages/#{name}")
    end

    def self.mapping(project)
      metadata = project['metadata']
      repo = metadata['repository'].is_a?(Hash) ? metadata['repository']['url'] : metadata['repository']
      {
        :name => project['name'],
        :description => metadata['description'],
        :repository_url => repo_fallback(repo, '')
      }
    end

    def self.versions(project)
      project['versions'].map do |k,_v|
        {
          :number => k,
          :published_at => nil
        }
      end
    end

    def self.dependencies(name, version, _project)
      deps = get("https://atom.io/api/packages/#{name}/versions/#{version}")["dependencies"] || []
      deps.map do |dep_name,req|
        {
          project_name: dep_name,
          requirements: req,
          kind: 'normal',
          optional: false,
          platform: 'Npm' # woah!
        }
      end
    end
  end
end
