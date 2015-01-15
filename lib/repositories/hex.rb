class Repositories
  class Hex < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true

    def self.project_names
      page = 1
      projects = []
      while true
        r = get("https://hex.pm/api/packages?page=#{page}")
        break if r == []
        projects += r
        page +=1
      end
      projects.map{|project| project['name'] }
    end

    def self.project(name)
      get("https://hex.pm/api/packages/#{name}")
    end

    def self.mapping(project)
      {
        :name => project["name"],
        :homepage => project["meta"].fetch("links", {}).fetch("GitHub", ''),
        :description => project["meta"]["description"],
        :licenses => project["meta"].fetch("licenses", []).join(',')
      }
    end

    def self.versions(project)
      project["releases"].map do |version|
        {
          :number => version['version'],
          :published_at => version['created_at']
        }
      end
    end
  end
end
