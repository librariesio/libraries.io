class Repositories
  class Jam < Base
    HAS_VERSIONS = true

    def self.project_names
      projects.keys.sort
    end

    def self.projects
      @projects ||= begin
        prjcts = {}
        packages = JSON.parse(HTTParty.get("http://jamjs.org/repository/_design/jam-packages/_view/packages_by_category?reduce=false&include_docs=true&startkey=%5B%22All%22%5D&endkey=%5B%22All%22%2C%7B%7D%5D&limit=2000&skip=0").parsed_response)['rows']

        packages.each do |package|
          prjcts[package['id'].downcase] = package['doc']
        end

        prjcts
      end
    end

    def self.project(name)
      JSON.parse HTTParty.get("http://jamjs.org/repository/#{name}").parsed_response
    end

    def self.mapping(project)
      {
        :name => project["name"],
        :description => project["description"],
        :homepage => project["homepage"],
        :keywords => (project["keywords"].present? ? project["keywords"].join(',') : '')
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
