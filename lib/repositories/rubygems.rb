require 'gems'

class Repositories
  class Rubygems
    def self.project_names
      gems = Marshal.load(Gem.gunzip(HTTParty.get("http://production.cf.rubygems.org/specs.4.8.gz").parsed_response))
      gems.map(&:first).uniq
    end

    def self.project(name)
      Gems.info name
    end

    def self.keys
      ["name", "downloads", "version", "version_downloads", "platform", "authors", "info", "licenses", "project_uri", "gem_uri", "homepage_uri", "wiki_uri", "documentation_uri", "mailing_list_uri", "source_code_uri", "bug_tracker_uri", "dependencies"]
    end

    def self.mapping(project)
      {
        :name => project["name"],
        :description => project["info"],
        :homepage => project["homepage_uri"]
      }
    end
  end
end
