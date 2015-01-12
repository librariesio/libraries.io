class Repositories
  class NPM < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true

    def self.project_names
      HTTParty.get("http://registry.npmjs.org/-/all/").parsed_response.keys[1..-1]
    end

    def self.project(name)
      HTTParty.get("http://registry.npmjs.org/#{name}").parsed_response
    end

    def self.keys
      ["_id", "_rev", "name", "description", "dist-tags", "versions", "readme", "maintainers", "time", "author", "repository", "users", "homepage", "keywords", "bugs", "readmeFilename", "_attachments"]
    end

    def self.mapping(project)
      return false unless project["versions"].present?
      latest_version = project["versions"].to_a.last[1]
      {
        :name => project["name"],
        :description => project["description"],
        :homepage => project["homepage"],
        :keywords => project.fetch("keywords", []).join(','),
        :licenses => Array.wrap(latest_version.fetch('licenses', [])).map{|l| l['type'] }.join(',')
      }
    end

    def self.versions(project)
      if project['time']
        project['time'].except("modified", "created").map do |k,v|
          {
            :number => k,
            :published_at => v
          }
        end
      else
        project['versions'].map do |_k, v|
          { :number => v['version'] }
        end
      end
    end
  end
end
