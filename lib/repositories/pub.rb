class Repositories
  class Pub < Base
    HAS_VERSIONS = true

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
      latest_version = r['versions'].last
      {
        :name => project["name"],
        :homepage => latest_version['pubspec']['homepage'],
        :description => latest_version['pubspec']['description']
      }
    end

    def self.versions(project)
      Gems.versions(project['name']).map do |v|
        {
          :number => v['version']
        }
      end
    end

    # TODO repo, authors, versions
  end
end
