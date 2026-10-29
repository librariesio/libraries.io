# frozen_string_literal: true

module PackageManager
  class Julia < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    URL = "http://pkg.julialang.org/"
    COLOR = "#a270ba"
    # Names are used as filesystem path segments, so reject anything that could traverse or escape.
    SAFE_NAME = /\A[A-Za-z0-9_][A-Za-z0-9_.+-]*\z/

    def self.package_link(db_project, _version = nil)
      "http://pkg.julialang.org/?pkg=#{db_project.name}&ver=release"
    end

    def self.project_names
      @project_names ||= `rm -rf Specs;git clone https://github.com/JuliaLang/METADATA.jl --depth 1; ls METADATA.jl`.split("\n")
    end

    def self.project(name)
      return unless SAFE_NAME.match?(name)

      dir = File.join("METADATA.jl", name)
      versions_dir = File.join(dir, "versions")
      url_file = File.join(dir, "url")
      return unless File.directory?(versions_dir) && File.file?(url_file)

      versions = Dir.children(versions_dir).sort
      repository_url = File.read(url_file)
      {
        name: name,
        versions: versions,
        repository_url: repository_url,
      }
    end

    def self.mapping(raw_project)
      MappingBuilder.build_hash(
        name: raw_project[:name],
        description: nil, # TODO: can we get description?
        repository_url: repo_fallback(raw_project[:repository_url], "")
      )
    end

    def self.versions(raw_project, _name)
      raw_project["versions"].map do |v|
        VersionBuilder.build_hash(
          number: v
        )
      end
    end
  end
end
