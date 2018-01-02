module PackageManager
  class NPM < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    SECURITY_PLANNED = true
    URL = 'https://www.npmjs.com'
    COLOR = '#f1e05a'

    def self.package_link(project, _version = nil)
      "https://www.npmjs.com/package/#{project.name}"
    end

    def self.download_url(name, version = nil)
      "https://registry.npmjs.org/#{name}/-/#{name}-#{version}.tgz"
    end

    def self.install_instructions(project, version = nil)
      "npm install #{project.name}" + (version ? "@#{version}" : "")
    end

    def self.formatted_name
      'npm'
    end

    def self.project_names
      get("https://raw.githubusercontent.com/nice-registry/all-the-package-names/master/names.json")
    end

    def self.recent_names
      u = 'http://registry.npmjs.org/-/rss?descending=true&limit=50'
      SimpleRSS.parse(get_raw(u)).items.map(&:title).uniq
    end

    def self.project(name)
      get("http://registry.npmjs.org/#{name.gsub('/', '%2F')}")
    end

    def self.mapping(project)
      return false unless project["versions"].present?
      latest_version = project["versions"].to_a.last[1]

      repo = latest_version.fetch('repository', {})
      repo = repo[0] if repo.is_a?(Array)
      repo_url = repo.try(:fetch, 'url', nil)

      {
        :name => project["name"],
        :description => latest_version["description"],
        :homepage => project["homepage"],
        :keywords_array => Array.wrap(latest_version.fetch("keywords", [])),
        :licenses => licenses(latest_version),
        :repository_url => repo_fallback(repo_url, project["homepage"]),
        :versions => project["versions"]
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
      project['versions'].map do |k, v|
        {
          :number => k,
          :published_at => project.fetch('time', {}).fetch(k, nil)
        }
      end
    end

    def self.dependencies(name, version, project)
      vers = project[:versions][version]
      return [] if vers.nil?
      map_dependencies(vers.fetch('dependencies', {}), 'runtime') +
      map_dependencies(vers.fetch('devDependencies', {}), 'Development') +
      map_dependencies(vers.fetch('optionalDependencies', {}), 'Optional', true)
    end
  end
end
