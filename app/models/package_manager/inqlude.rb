# frozen_string_literal: true

module PackageManager
  class Inqlude < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    URL = "https://inqlude.org/"
    COLOR = "#f34b7d"

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
      versions = `ls inqlude-data/#{name}`.split("\n").sort
      version = versions.last
      Oj.load `cat inqlude-data/#{name}/#{version}`
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
