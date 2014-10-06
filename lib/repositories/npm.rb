module Repositories
  class Npm
    def self.project_names
      HTTParty.get("https://registry.npmjs.org/-/all/").parsed_response.keys[1..-1]
    end

    def self.project(name)
      HTTParty.get("http://registry.npmjs.org/#{name}").parsed_response
    end
  end
end
