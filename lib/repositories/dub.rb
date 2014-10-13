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
        :homepage => project["repository"],
        :keywords => project["categories"]
      }
    end

    # TODO repo, versions, authors
  end
end
