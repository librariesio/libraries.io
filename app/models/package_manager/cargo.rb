module PackageManager
  class Cargo < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    URL = 'https://crates.io'
    COLOR = '#dea584'

    def self.package_link(project, version = nil)
      "https://crates.io/crates/#{project.name}/#{version}"
    end

    def self.download_url(name, version = nil)
      "https://crates.io/api/v1/crates/#{name}/#{version}/download"
    end

    def self.documentation_url(name, version = nil)
      "https://docs.rs/#{name}/#{version}"
    end

    def self.check_status_url(project)
      "https://crates.io/api/v1/crates/#{project.name}"
    end

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

    def self.recent_names
      json = get("https://crates.io/summary")
      updated_names = json['just_updated'].map{|c| c['name']}
      new_names = json['new_crates'].map{|c| c['name']}
      (updated_names + new_names).uniq
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

    def self.dependencies(name, version, _project)
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
