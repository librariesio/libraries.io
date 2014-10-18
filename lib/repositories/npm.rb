class Repositories
  class NPM < Base
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
      latest_version = project["versions"].to_a.last[1]
      {
        :name => project["name"],
        :description => project["description"],
        :homepage => project["homepage"],
        :keywords => (project["keywords"].present? ? project["keywords"].join(',') : ''),
        :licenses => latest_version['licenses'].map{|l| l['type'] }.join(',')
      }
    end

    def self.versions(project)
      project['time'].except("modified", "created").map do |k,v|
        {
          :number => k,
          :published_at => v
        }
      end
    end
  end
end
