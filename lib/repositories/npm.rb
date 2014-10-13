class Repositories
  class Npm < Base
    HAS_VERSIONS = true
    
    def self.project_names
      HTTParty.get("https://registry.npmjs.org/-/all/").parsed_response.keys[1..-1]
    end

    def self.project(name)
      HTTParty.get("http://registry.npmjs.org/#{name}").parsed_response
    end

    def self.keys
      ["_id", "_rev", "name", "description", "dist-tags", "versions", "readme", "maintainers", "time", "author", "repository", "users", "homepage", "keywords", "bugs", "readmeFilename", "_attachments"]
    end

    def self.mapping(project)
      {
        :name => project["name"],
        :description => project["description"],
        :homepage => project["homepage"],
        :keywords => project["keywords"].join(',')
      }
    end

    # TODO repo, authors, versions, licenses
  end
end
