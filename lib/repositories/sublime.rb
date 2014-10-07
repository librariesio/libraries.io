class Repositories
  class Sublime
    def self.project_names
      projects.keys.sort
    end

    def self.projects
      @projects ||= begin
        prjcts = {}
        packages = HTTParty.get("https://sublime.wbond.net/channel.json").parsed_response['packages_cache']
        packages.each do |json, pkgs|
          pkgs.each do |pkg|
            prjcts[pkg['name'].downcase] = pkg.slice("name", "labels", "homepage", "description", "author", "donate", "issues", "releases", "name", "buy", "readme")
          end
        end
        prjcts
      end
    end

    def self.project(name)
      projects[name.downcase]
    end

    def self.keys
      ["labels", "homepage", "description", "author", "donate", "issues", "releases", "name", "buy", "readme"]
    end

    def self.mapping(project)
      {
        :name => project["name"],
        :description => project["description"],
        :homepage => project["homepage"],
        :keywords => project["labels"]
      }
    end

    # TODO repo, authors, versions
  end
end
