class Repositories
  class Pub < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    URL = 'https://pub.dartlang.org'
    COLOR = '#98BAD6'

    def self.project_names
      page = 1
      projects = []
      while true
        r = get("https://pub.dartlang.org/api/packages?page=#{page}")
        break if r['packages'] == []
        projects += r['packages']
        page +=1
      end
      projects.map{|project| project['name'] }.sort
    end

    def self.project(name)
      get("https://pub.dartlang.org/api/packages/#{name}")
    end

    def self.mapping(project)
      latest_version = project['versions'].last
      {
        :name => project["name"],
        :homepage => latest_version['pubspec']['homepage'],
        :description => latest_version['pubspec']['description'],
        :repository_url => repo_fallback('', latest_version['pubspec']['homepage'])
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
