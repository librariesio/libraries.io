# frozen_string_literal: true

module PackageManager
  class Atom < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    SECURITY_PLANNED = true
    URL = "https://atom.io"
    COLOR = "#244776"

    def self.package_link(project, _version = nil)
      "https://atom.io/packages/#{CGI.escape(project.name.strip)}"
    end

    def self.download_url(name, version = nil)
      "https://www.atom.io/api/packages/#{CGI.escape(name.strip)}/versions/#{version}/tarball"
    end

    def self.install_instructions(project, version = nil)
      "apm install #{project.name}" + (version ? "@#{version}" : "")
    end

    def self.project_names
      page = 1
      projects = []
      loop do
        r = get("https://atom.io/api/packages?page=#{page}")
        break if r == []

        projects += r
        page += 1
      end
      projects.map { |project| project["name"] }.sort.uniq
    end

    def self.recent_names
      projects = get("https://atom.io/api/packages?page=1&sort=created_at&direction=desc") +
                 get("https://atom.io/api/packages?page=1&sort=updated_at&direction=desc")
      projects.map { |project| project["name"] }.uniq
    end

    def self.project(name)
      get("https://atom.io/api/packages/#{CGI.escape(name.strip)}")
    end

    def self.mapping(project)
      metadata = project["metadata"]
      metadata = project if metadata.nil?
      repo = metadata["repository"].is_a?(Hash) ? metadata["repository"]["url"] : metadata["repository"]
      {
        name: project["name"],
        description: metadata["description"],
        repository_url: repo_fallback(repo, ""),
      }
    end

    def self.versions(project, _name)
      project["versions"].map do |k, _v|
        {
          number: k,
          published_at: nil,
        }
      end
    end

    def self.dependencies(_name, version, project)
      vers = project[:versions][version]
      return [] if vers.nil?

      map_dependencies(vers.fetch("dependencies", {}), "runtime", false, "Npm") +
        map_dependencies(vers.fetch("devDependencies", {}), "Development", false, "Npm") +
        map_dependencies(vers.fetch("optionalDependencies", {}), "Optional", true, "Npm")
    end
  end
end
