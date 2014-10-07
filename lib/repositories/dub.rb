class Repositories
  class Dub
    def self.project_names
      HTTParty.get("http://code.dlang.org/packages/index.json").parsed_response.sort
    end

    def self.project(name)
      HTTParty.get("http://code.dlang.org/packages/#{name}.json").parsed_response
    end
  end
end
