module Repositories
  class Elm < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    LIBRARIAN_SUPPORT = true
    URL = 'http://package.elm-lang.org/'
    COLOR = '#60B5CC'

    def self.package_link(project, version = nil)
      "http://package.elm-lang.org/packages/#{project.name}/#{version || 'latest'}"
    end

    def self.install_instructions(project, version = nil)
      "elm-package install #{project.name} #{version}"
    end

    def self.project_names
      projects.keys
    end

    def self.projects
      @projects ||= begin
        prjs = {}
        get('http://package.elm-lang.org/all-packages').each do |prj|
          prjs[prj['name']] = prj
        end
        prjs
      end
    end

    def self.recent_names
      get("http://package.elm-lang.org/new-packages")
    end

    def self.project(name)
      projects[name]
    end

    def self.mapping(project)
      {
        :name => project["name"],
        :description => project["summary"],
        :repository_url => "https://github.com/#{project["name"]}"
      }
    end

    def self.versions(project)
      project['versions'].map do |v|
        { :number => v }
      end
    end

    def self.dependencies(name, version, project)
      find_and_map_dependencies(name, version, project)
    end

    def self.find_dependencies(name, version)
      begin
        url = "https://raw.githubusercontent.com/#{name}/#{version}/elm-package.json"

        contents = Typhoeus.get(url).body

        r = Typhoeus::Request.new("https://librarian.libraries.io/v2/parse_file?filepath=elm-package.json",
          method: :post,
          body: {contents: contents},
          headers: { 'Accept' => 'application/json' }).run
        return Oj.load(r.body)
      rescue
        []
      end
    end
  end
end
