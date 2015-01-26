class Repositories
  class Dub < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    URL = 'http://code.dlang.org'

    def self.project_names
      get("http://code.dlang.org/packages/index.json").sort
    end

    def self.project(name)
      get("http://code.dlang.org/packages/#{name}.json")
    end

    def self.mapping(project)
      latest_version = project["versions"].last
      {
        :name => project["name"],
        :description => latest_version['description'],
        :homepage => latest_version['homepage'],
        :keywords => project["categories"].join(','),
        :licenses => latest_version['license'],
        :repository_url => repository(project["repository"])
      }
    end

    def self.versions(project)
      project["versions"].map do |v|
        {
          :number => v['version'],
          :published_at => v['date']
        }
      end
    end

    def self.repository(hash)
      if hash['kind'] == 'github'
        "https://github.com/#{hash['owner']}/#{hash['project']}"
      elsif hash['kind'] == 'bitbucket'
        "https://bitbucket.org/#{hash['owner']}/#{hash['project']}"
      else
        raise hash
      end
    end
  end
end
