# frozen_string_literal: true
module PackageManager
  class Emacs < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    URL = 'http://melpa.org'
    COLOR = '#c065db'

    def self.package_link(project, version = nil)
      "http://melpa.org/#/#{project.name}"
    end

    def self.download_url(name, version = nil)
      "http://melpa.org/packages/#{name}-#{version}.tar"
    end

    def self.project_names
      projects.keys.sort
    end

    def self.projects
      @projects ||= get("http://melpa.org/archive.json")
    end

    def self.project(name)
      return nil if projects[name].nil?
      projects[name].merge({"name" => name})
    end

    def self.mapping(project)
      {
        name: project["name"],
        description: project["desc"],
        repository_url: project.fetch("props", {}).try(:fetch, 'url', ''),
        keywords_array: Array.wrap(project.fetch("props", {}).try(:fetch, 'keywords', []))
      }
    end
  end
end
