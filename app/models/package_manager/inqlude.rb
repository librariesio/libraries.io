# frozen_string_literal: true

module PackageManager
  class Inqlude < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    URL = "https://inqlude.org/"
    COLOR = "#f34b7d"
    # Names are used as filesystem path segments, so reject anything that could traverse or escape.
    SAFE_NAME = /\A[A-Za-z0-9_][A-Za-z0-9_.+-]*\z/

    def self.package_link(db_project, _version = nil)
      "https://inqlude.org/libraries/#{db_project.name}.html"
    end

    def self.install_instructions(db_project, _version = nil)
      "inqlude install #{db_project.name}"
    end

    def self.project_names
      @project_names ||= `rm -rf inqlude-data;git clone https://github.com/cornelius/inqlude-data.git --depth 1; ls -l inqlude-data/ | grep "^d" | awk -F" " '{print $9}'`.split("\n")
    end

    def self.project(name)
      return unless SAFE_NAME.match?(name)

      dir = File.join("inqlude-data", name)
      return unless File.directory?(dir)

      version = Dir.children(dir).max
      return if version.nil?

      Oj.load(File.read(File.join(dir, version)))
    end

    def self.mapping(raw_project)
      MappingBuilder.build_hash(
        name: raw_project["name"],
        description: raw_project["summary"],
        homepage: raw_project["urls"]["homepage"],
        licenses: raw_project["licenses"].join(","),
        repository_url: repo_fallback(raw_project["urls"]["vcs"], "")
      )
    end
  end
end
