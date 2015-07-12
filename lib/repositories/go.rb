class Repositories
  class Go < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    URL = 'http://go-search.org/'
    COLOR = '#375eab'

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
