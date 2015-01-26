class Repositories
  class Sublime < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    URL = 'https://packagecontrol.io'

    def self.project_names
      get("https://packagecontrol.io/channel.json")['packages_cache'].map{|k,v| v[0]['name']}
    end

    def self.project(name)
      get("https://packagecontrol.io/packages/#{URI.escape(name)}.json")
    end

    def self.mapping(project)
      {
        :name => project["name"],
        :description => project["description"],
        :homepage => project["homepage"],
        :repository_url => parse_repo(project["issues"]),
        :keywords => project["labels"].join(',')
      }
    end

    def self.versions(project)
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
