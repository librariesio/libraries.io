class Repositories
  class NPM < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    URL = 'https://www.npmjs.com'

    def self.project_names
      get("http://registry.npmjs.org/-/all/").keys[1..-1]
    end

    def self.project(name)
      get("http://registry.npmjs.org/#{name}")
    end

    def self.keys
      ["_id", "_rev", "name", "description", "dist-tags", "versions", "readme", "maintainers", "time", "author", "repository", "users", "homepage", "keywords", "bugs", "readmeFilename", "_attachments"]
    end

    def self.mapping(project)
      return false unless project["versions"].present?
      latest_version = project["versions"].to_a.last[1]
      {
        :name => project["name"],
        :description => latest_version["description"],
        :homepage => project["homepage"],
        :keywords => Array.wrap(latest_version.fetch("keywords", [])).join(','),
        :licenses => latest_version.fetch('license'),
        :repository_url => latest_version.fetch('repository', {})['url']
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
