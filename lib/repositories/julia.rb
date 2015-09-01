class Repositories
  class Julia < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    LIBRARIAN_PLANNED = true
    URL = 'http://pkg.julialang.org/'
    COLOR = '#a270ba'

    def self.project_names
      @project_names ||= `rm -rf Specs;git clone https://github.com/JuliaLang/METADATA.jl --depth 1; ls METADATA.jl`.split("\n")
    end

    def self.project(name)
      versions = `ls METADATA.jl/#{name}/versions`.split("\n").sort
      version = versions.last
      repository_url = `cat METADATA.jl/#{name}/url`
      {
        name: name,
        versions: versions,
        repository_url: repository_url
      }
    end

    def self.mapping(project)
      {
        :name => project[:name],
        :repository_url => repo_fallback(project[:repository_url], '')
      }
    end

    def self.versions(project)
      project['versions'].map do |v|
        {
          :number => v
        }
      end
    end
  end
end
