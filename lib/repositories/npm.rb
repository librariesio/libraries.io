class Repositories
  class Npm
    def self.project_names
      HTTParty.get("https://registry.npmjs.org/-/all/").parsed_response.keys[1..-1]
    end

    def self.project(name)
      HTTParty.get("http://registry.npmjs.org/#{name}").parsed_response
    end

    def self.keys
      ["_id", "_rev", "name", "dist-tags", "versions", "readme", "maintainers", "time", "readmeFilename", "license", "users", "_attachments"]
    end

    def self.mapping(project)
      {
        :name => project["name"],
        :published_at => project["time"],
      }
    end
  end
end
