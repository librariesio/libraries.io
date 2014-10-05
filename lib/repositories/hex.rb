module Repositories
  class Hex
    def self.project_names
      page = 1
      projects = []
      while true
        r = HTTParty.get("https://hex.pm/api/packages?page=#{page}").parsed_response
        break if r == []
        projects += r
        page +=1
      end
      projects.map{|project| project['name'] }
    end

    def self.project(name)
      HTTParty.get("https://hex.pm/api/packages/#{name}").parsed_response
    end
  end
end
