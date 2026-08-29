# frozen_string_literal: true

module PackageManager
  class Spack < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    HAS_OWNERS = true
    
    # spack generates a spec.json for each package installed
    BIBLIOTHECARY_PLANNED = true
    URL = "https://spack.io"
    COLOR = "#0d3d7e"

    def self.formatted_name
      'spack'
    end

    def self.package_link(db_project, version = nil)
      "https://spack.github.io/packages/package.html?name=#{db_project.name}"
    end

    def self.project_names
      get_json("https://spack.github.io/packages/data/packages.json")
    rescue StandardError
      {}
    end

    def self.documentation_url(name, version = nil)
      "https://spack.github.io/packages/package.html?name=#{db_project.name}"
    end

    def self.project(name)
      get_json("https://spack.github.io/packages/data/packages/#{name}.json")
    rescue StandardError
      {}
    end

    def self.mapping(raw_project)
      {
        name: raw_project["name"],
        description: raw_project["description"],
        homepage: raw_project["homepage"],
        licenses: [],
        repository_url: raw_project["homepage"],
      }
    end

    def self.versions(raw_project, _name)
      json = get_json("https://spack.github.io/packages/data/packages/#{name}.json")
      json.map do |v|
        {
          number: v["name"],
          # We have a sha256 if that is needed.
          # We don't have this information easily, it's in git
          published_at: Time.now.strftime("%d-%m-%Y %H:%M")
        }
      end
    rescue StandardError
      []
    end

    def self.dependencies(name, version, _mapped_project)
      json = get_json("https://spack.github.io/packages/data/packages/#{name}.json")
      return [] unless json['dependencies']
      deps = json["dependencies"]
      deps.map do |dep|
        {
          project_name: dep["name"],

          # This is determined by the solver at install
          requirements: '*',

          # We have this information but not exposed via API
          kind: 'runtime',
          platform: self.name.demodulize
        }
    rescue StandardError
      []
    end

    def self.install_instructions(db_project, version = nil)
      "spack install #{db_project.name}" + (version ? "@#{version}" : "")
    end
  end
end
