module Repositories
  class NPM < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    LIBRARIAN_SUPPORT = true
    SECURITY_PLANNED = true
    URL = 'https://www.npmjs.com'
    COLOR = '#f1e05a'

    def self.package_link(name, version = nil)
      "https://www.npmjs.com/package/#{name}"
    end

    def self.install_instructions(project, version = nil)
      "npm install #{project.name}" + (version ? "@#{version}" : "")
    end

    def self.formatted_name
      'npm'
    end

    def self.project_names
      get("https://registry.npmjs.org/-/all").keys[1..-1]
    end

    def self.recent_names
      u = 'http://registry.npmjs.org/-/rss?descending=true&limit=50'
      SimpleRSS.parse(get_raw(u)).items.map(&:title).uniq
    end

    def self.project(name)
      get("http://registry.npmjs.org/#{name.gsub('/', '%2F')}")
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
        :keywords_array => Array.wrap(latest_version.fetch("keywords", [])),
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
        licenses.map do |lice|
          if lice.is_a?(Hash)
            lice.fetch('type', '')
          else
            lice
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
      versions.reject {|version,date| version_invalid?(project['name'], version[:number]) }
    end

    def self.version_invalid?(name, version)
      get("http://registry.npmjs.org/#{name.gsub('/', '%2F')}/#{version}").try(:has_key?, 'error')
    end

    def self.dependencies(name, version, _project)
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
