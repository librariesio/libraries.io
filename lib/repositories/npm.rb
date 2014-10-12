class Repositories
  class Npm
    PLATFORM = 'npm'

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

    def self.save(project)
      mapped_project = mapping(project)
      project = Project.find_or_create_by({:name => mapped_project[:name], :platform => PLATFORM})
      project.update_attributes(mapped_project.slice(:description, :homepage, :keywords))
      project
    end

    def self.update(name)
      save(project(name))
    end

    # TODO repo, authors, versions, licenses
  end
end
