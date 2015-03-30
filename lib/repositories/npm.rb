class Repositories
  class NPM < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    URL = 'https://www.npmjs.com'
    COLOR = '#f1e05a'

    def self.project_names
      get("http://registry.npmjs.org/-/all/").keys[1..-1]
    end

    def self.recent_names
      u = 'http://registry.npmjs.org/-/rss?descending=true&limit=50'
      titles = SimpleRSS.parse(Typhoeus.get(u).body).items.map(&:title)
      titles.map { |t| t.split('@').first }
    end

    def self.project(name)
      get("http://registry.npmjs.org/#{name}")
    end

    def self.keys
      ["_id", "_rev", "name", "description", "dist-tags", "versions", "readme", "maintainers", "time", "author", "repository", "users", "homepage", "keywords", "bugs", "readmeFilename", "_attachments"]
    end

    def self.mapping(project)
      return false unless project["versions"].present?
      latest_version = project["versions"].to_a.last[1]
      {
        :name => project["name"],
        :description => latest_version["description"],
        :homepage => project["homepage"],
        :keywords => Array.wrap(latest_version.fetch("keywords", [])).join(','),
        :licenses => licenses(latest_version),
        :repository_url => repo_fallback(latest_version.fetch('repository', {})['url'],project["homepage"])
      }
    end

    def self.licenses(latest_version)
      license = latest_version.fetch('license', nil)
      if license.present?
        if license.is_a?(Hash)
          return license.fetch('type', '')
        else
          return license
        end
      else
        licenses = Array(latest_version.fetch('licenses', []))
        licenses.map do |license|
          if license.is_a?(Hash)
            license.fetch('type', '')
          else
            license
          end
        end.join(',')
      end
    end

    def self.versions(project)
      versions = if project['time']
        project['time'].except("modified", "created").map do |k,v|
          {
            :number => k,
            :published_at => v
          }
        end
      else
        project['versions'].map do |_k, v|
          { :number => v['version'] }
        end
      end
      versions.reject {|number,date| version_invalid?(project['name'], number) }
    end

    def self.version_invalid?(name, version)
      get("http://registry.npmjs.org/#{name}/#{version}").has_key?('error')
    end

    def self.dependencies(name, version)
      proj = project(name)
      vers = proj['versions'][version]
      return [] if vers.nil?
      vers.fetch('dependencies', {}).map do |k,v|
        {
          project_name: k,
          requirements: v,
          kind: 'normal',
          optional: false,
          platform: self.name.demodulize
        }
      end + vers.fetch('devDependencies', {}).map do |k,v|
        {
          project_name: k,
          requirements: v,
          kind: 'Development',
          optional: false,
          platform: self.name.demodulize
        }
      end + vers.fetch('optionalDependencies', {}).map do |k,v|
        {
          project_name: k,
          requirements: v,
          kind: 'Optional',
          optional: true,
          platform: self.name.demodulize
        }
      end
    end
  end
end
