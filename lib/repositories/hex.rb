class Repositories
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

    def self.keys
      ["created_at", "downloads", "meta", "name", "releases", "updated_at", "url"]
    end

    def self.mapping(project)
      {
        :name => project["name"],
        :homepage => project["url"],
        :published_at => project["created_at"],
      }
    end
  end
end
