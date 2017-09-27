module PackageManager
  class Rubygems < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    SECURITY_PLANNED = true
    URL = 'https://rubygems.org'
    COLOR = '#701516'

    def self.package_link(project, version = nil)
      "https://rubygems.org/gems/#{project.name}" + (version ? "/versions/#{version}" : "")
    end

    def self.download_url(name, version = nil)
      "https://rubygems.org/downloads/#{name}-#{version}.gem"
    end

    def self.documentation_url(name, version = nil)
      "http://www.rubydoc.info/gems/#{name}/#{version}"
    end

    def self.install_instructions(project, version = nil)
      "gem install #{project.name}" + (version ? " -v #{version}" : "")
    end

    def self.check_status_url(project)
      "https://rubygems.org/api/v1/versions/#{project.name}.json"
    end

    def self.project_names
      gems = Marshal.load(Gem.gunzip(get_raw("http://production.cf.rubygems.org/specs.4.8.gz")))
      gems.map(&:first).uniq
    end

    def self.recent_names
      updated = get('https://rubygems.org/api/v1/activity/just_updated.json').map{|h| h['name']}
      new_gems = get('https://rubygems.org/api/v1/activity/latest.json').map{|h| h['name']}
      (updated + new_gems).uniq
    end

    def self.project(name)
      get_json("https://rubygems.org/api/v1/gems/#{name}.json")
    rescue
      {}
    end

    def self.mapping(project)
      {
        :name => project["name"],
        :description => project["info"],
        :homepage => project["homepage_uri"],
        :licenses => project.fetch("licenses", []).try(:join, ','),
        :repository_url => repo_fallback(project['source_code_uri'],project["homepage_uri"])
      }
    end

    def self.versions(project)
      json = get_json("https://rubygems.org/api/v1/versions/#{project['name']}.json")
      json.map do |v|
        {
          :number => v['number'],
          :published_at => v['created_at']
        }
      end
    rescue
      []
    end

    def self.dependencies(name, version, _project)
      json = get_json("https://rubygems.org/api/v2/rubygems/#{name}/versions/#{version}.json")

      deps = json['dependencies']
      map_dependencies(deps['development'], 'Development') + map_dependencies(deps['runtime'], 'runtime')
    rescue
      []
    end

    def self.map_dependencies(deps, kind)
      deps.map do |dep|
        {
          project_name: dep['name'],
          requirements: dep['requirements'],
          kind: kind,
          platform: self.name.demodulize
        }
      end
    end
  end
end
