module PackageManager
  class Sublime < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    URL = 'https://packagecontrol.io'
    COLOR = '#3572A5'

    def self.package_link(project, version = nil)
      "https://packagecontrol.io/packages/#{project.name}"
    end

    def self.project_names
      get("https://packagecontrol.io/channel.json")['packages_cache'].map{|_k,v| v[0]['name']}
    end

    def self.project(name)
      get("https://packagecontrol.io/packages/#{URI.escape(name)}.json")
    end

    def self.mapping(project)
      {
        :name => project["name"],
        :description => project["description"],
        :homepage => project["homepage"],
        :repository_url => repo_fallback(parse_repo(project["issues"]),project["homepage"]),
        :keywords_array => Array.wrap(project["labels"])
      }
    end

    def self.versions(project, name)
      project['versions'].map do |v|
        {
          :number => v['version']
        }
      end
    end

    def self.parse_repo(url)
      return nil unless url
      url.gsub(/\/issues(\/)?/i, '')
    end
  end
end
