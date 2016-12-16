module Repositories
  class Pub < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    LIBRARIAN_SUPPORT = true
    URL = 'https://pub.dartlang.org'
    COLOR = '#98BAD6'

    def self.package_link(name, version = nil)
      "https://pub.dartlang.org/packages/#{name}"
    end

    def self.documentation_url(name, version = nil)
      "http://www.dartdocs.org/documentation/#{name}/#{version}"
    end

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

    def self.recent_names
      get("https://pub.dartlang.org/api/packages?page=1")['packages'].map{|project| project['name'] }
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

    def self.dependencies(name, version, _project)
      proj = project(name)
      vers = proj['versions'].find{|v| v['version'] == version }

      return [] if vers.nil?
      vers['pubspec'].fetch('dependencies', {}).map do |k,v|
        {
          project_name: k,
          requirements: v,
          kind: 'normal',
          optional: false,
          platform: self.name.demodulize
        }
      end + vers['pubspec'].fetch('dev_dependencies', {}).map do |k,v|
        {
          project_name: k,
          requirements: v,
          kind: 'normal',
          optional: false,
          platform: self.name.demodulize
        }
      end
    end
  end
end
