module PackageManager
  class Meteor < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_SUPPORT = true
    URL = 'https://atmospherejs.com'
    COLOR = '#f1e05a'

    def self.package_link(project, version = nil)
      "https://atmospherejs.com/#{project.name.tr(':', '/')}"
    end

    def self.install_instructions(project, version = nil)
      "meteor add #{project.name}" + (version ? "@=#{version}" : "")
    end

    def self.project_names
      projects.keys
    end

    def self.projects
      @projects ||= begin
        projects = {}
        packages = get_json("https://atmospherejs.com/a/packages")

        packages.each do |hash|
          next if hash['latestVersion'].nil?
          projects[hash['name'].downcase] = hash['latestVersion'].merge({'name' => hash['name']})
        end

        projects
      end
    end

    def self.project(name)
      projects[name.downcase]
    end

    def self.mapping(project)
      {
        :name => project["name"],
        :description => project["description"],
        :repository_url => repo_fallback(project["git"], nil)
      }
    end

    def self.versions(project, name)
      [{
        :number => project['version'],
        :published_at => Time.at(project['published']['$date']/1000.0)
      }]
    end
  end
end
