class Repositories
  class Dub < Base
    def self.project_names
      HTTParty.get("http://code.dlang.org/packages/index.json").parsed_response.sort
    end

    def self.project(name)
      HTTParty.get("http://code.dlang.org/packages/#{name}.json").parsed_response
    end

    def self.mapping(project)
      {
        :name => project["name"],
        :homepage => homepage(project["repository"]),
        :keywords => project["categories"].join(',')
      }
    end

    def self.homepage(hash)
      if hash['kind'] == 'github'
        "https://github.com/#{hash['owner']}/#{hash['project']}"
      elsif hash['kind'] == 'bitbucket'
        "https://bitbucket.org/#{hash['owner']}/#{hash['project']}"
      else
        raise hash
      end
    end

    # TODO repo, versions, authors
  end
end
