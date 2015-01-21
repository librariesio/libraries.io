class Repositories
  class Bower < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = true

    def self.project_names
      projects.keys
    end

    def self.projects
      @projects ||= begin
        projects = {}
        p1 = get("https://bower-component-list.herokuapp.com")
        p2 = get("https://bower.herokuapp.com/packages")

        p2.each do |hash|
          projects[hash['name'].downcase] = hash.slice('name', 'url', 'hits')
        end

        p1.each do |hash|
          if projects[hash['name'].downcase]
            projects[hash['name'].downcase].merge! hash.slice('description', "owner", "website", "forks", "stars", "created", "updated")
          end
        end
        projects
      end
    end

    def self.project(name)
      projects[name.downcase]
    end

    def self.mapping(project)
      {
        :name => project["name"],
        :description => project["description"],
        :repository_url => project["website"] || project["url"]
      }
    end
  end
end
