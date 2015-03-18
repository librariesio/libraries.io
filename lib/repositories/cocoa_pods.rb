class Repositories
  class CocoaPods < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    URL = 'http://cocoapods.org/'
    COLOR = '#438eff'

    def self.project_names
      @project_names ||= `rm -rf Specs;git clone https://github.com/CocoaPods/Specs.git --depth 1; ls Specs/Specs`.split("\n")
    end

    def self.project(name)
      versions = `ls Specs/Specs/#{name}`.split("\n").sort
      version = versions.last
      json = Oj.load `cat Specs/Specs/#{name}/#{version}/#{name}.podspec.json`
      json.merge('versions' => versions)
    end

    def self.mapping(project)
      {
        :name => project['name'],
        :description => project["summary"],
        :homepage => project["homepage"],
        :licenses => project['license']['type'],
        :repository_url => repo_fallback(project['source']['git'], '')
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
