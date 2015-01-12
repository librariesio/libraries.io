class Repositories
  class Emacs < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = true

    def self.project_names
      projects.keys.sort
    end

    def self.projects
      @projects ||= HTTParty.get("http://melpa.org/archive.json").parsed_response
    end

    def self.project(name)
      projects[name].merge({"name" => name})
    end

    def self.mapping(project)
      {
        :name => project["name"],
        :description => project["desc"],
        :homepage => project.fetch("props", {}).try(:fetch, 'url', ''),
        :keywords => project.fetch("props", {}).try(:fetch, 'keywords', []).try(:join, ',')
      }
    end
  end
end
