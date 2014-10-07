module Repositories
  class Emacs
    def self.project_names
      projects.keys.sort
    end

    def self.projects
      @projects ||= HTTParty.get("http://melpa.milkbox.net/archive.json").parsed_response
    end

    def self.project(name)
      projects[name.downcase]
    end
  end
end
