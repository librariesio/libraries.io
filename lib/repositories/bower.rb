class Repositories
  class Bower < Base
    HAS_VERSIONS = false
    
    def self.project_names
      projects.keys
    end

    def self.projects
      @projects ||= begin
        projects = {}
        p1 = HTTParty.get("https://bower-component-list.herokuapp.com").parsed_response
        p2 = HTTParty.get("https://bower.herokuapp.com/packages").parsed_response

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
        :homepage => project["url"]
      }
    end

    # TODO repo, authors
  end
end
