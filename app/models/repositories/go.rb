module Repositories
  class Go < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    LIBRARIAN_SUPPORT = true
    URL = 'http://go-search.org/'
    COLOR = '#375eab'

    def self.package_link(project, version = nil)
      "http://go-search.org/view?id=#{project.name}"
    end

    def self.documentation_url(name, version = nil)
      "http://godoc.org/#{name}"
    end

    def self.install_instructions(project, version = nil)
      "go get #{project.name}"
    end

    def self.project_names
      get("http://go-search.org/api?action=packages")
    end

    def self.project(name)
      get("http://go-search.org/api?action=package&id=#{name}")
    end

    def self.mapping(project)
      {
        name: project['Package'],
        description: project['Synopsis'],
        homepage: project['ProjectURL'],
        repository_url: "https://#{project['Package']}"
      }
    end
  end
end
