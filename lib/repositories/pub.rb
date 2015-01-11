class Repositories
  class Pub < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true

    def self.project_names
      page = 1
      projects = []
      while true
        r = HTTParty.get("https://pub.dartlang.org/api/packages?page=#{page}").parsed_response
        break if r['packages'] == []
        projects += r['packages']
        page +=1
      end
      projects.map{|project| project['name'] }.sort
    end

    def self.project(name)
      HTTParty.get("https://pub.dartlang.org/api/packages/#{name}").parsed_response
    end

    def self.mapping(project)
      latest_version = project['versions'].last
      {
        :name => project["name"],
        :homepage => latest_version['pubspec']['homepage'],
        :description => latest_version['pubspec']['description']
      }
    end

    def self.versions(project)
      project['versions'].map do |v|
        {
          :number => v['version']
        }
      end
    end
  end
end
