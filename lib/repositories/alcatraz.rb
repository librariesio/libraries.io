class Repositories
  class Alcatraz < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false

    def self.project_names
      projects.keys.sort
    end

    def self.projects
      @projects ||= begin
        prjcts = {}
        packages = get_json("https://raw.githubusercontent.com/supermarin/alcatraz-packages/master/packages.json")['packages']
        packages.each do |category, pkgs|
          pkgs.each do |hash|
            prjcts[hash['name'].downcase] = hash.slice('name', 'url', 'description', 'screenshot')
            prjcts[hash['name'].downcase]['category'] = category
          end
        end
        prjcts
      end
    end

    def self.project(name)
      projects[name.downcase]
    end

    def self.mapping(project)
      {
        :name => project["name"],
        :description => project["description"],
        :homepage => project["url"]
      }
    end
  end
end
