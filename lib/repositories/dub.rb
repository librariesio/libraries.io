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
        :repository_url => repo_fallback(repository(project["repository"]),latest_version['homepage'])
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
        ''
      end
    end

    def self.dependencies(name, version)
      vers = project(name)['versions'].find{|v| v['version'] == version.number}
      return [] if vers.nil?
      deps = vers['dependencies']
      return [] if deps.nil?
      deps.map do |k,v|
        if v.is_a? Hash
          req = v["version"]
          optional = v["optional"]
        else
          req = v
          optional = false
        end
        {
          project_name: k,
          requirements: req,
          kind: 'normal',
          optional: optional,
          platform: self.name.demodulize
        }
      end
    end
  end
end
