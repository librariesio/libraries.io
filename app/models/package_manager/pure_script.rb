# frozen_string_literal: true

module PackageManager
  class PureScript < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_PLANNED = true
    URL = "https://github.com/purescript/psc-package"
    COLOR = "#1D222D"

    def self.project_names
      get("https://raw.githubusercontent.com/purescript/package-sets/master/packages.json").keys
    end

    def self.project(name)
      project = get("https://raw.githubusercontent.com/purescript/package-sets/master/packages.json")[name]
      project["name"] = name

      project
    end

    def self.mapping(raw_project)
      MappingBuilder.build_hash(
        name: raw_project["name"],
        description: nil, # TODO: can we get description?
        repository_url: raw_project["repo"]
      )
    end

    def self.install_instructions(db_project, _version = nil)
      "psc-package install #{db_project.name}"
    end
  end
end
