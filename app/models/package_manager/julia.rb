# frozen_string_literal: true

module PackageManager
  class Julia < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_SUPPORT = true
    URL = "http://pkg.julialang.org/"
    COLOR = "#a270ba"

    def self.package_link(db_project, _version = nil)
      "http://pkg.julialang.org/?pkg=#{db_project.name}&ver=release"
    end

    def self.project_names
      @project_names ||= `rm -rf Specs;git clone https://github.com/JuliaLang/METADATA.jl --depth 1; ls METADATA.jl`.split("\n")
    end

    def self.project(name)
      versions = `ls METADATA.jl/#{name}/versions`.split("\n").sort
      repository_url = `cat METADATA.jl/#{name}/url`
      {
        name: name,
        versions: versions,
        repository_url: repository_url,
      }
    end

    def self.mapping(raw_project)
      {
        name: raw_project[:name],
        repository_url: repo_fallback(raw_project[:repository_url], ""),
      }
    end

    def self.versions(raw_project, _name)
      raw_project["versions"].map do |v|
        {
          number: v,
        }
      end
    end
  end
end
