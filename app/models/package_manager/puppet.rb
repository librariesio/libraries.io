module PackageManager
  class Puppet < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_SUPPORT = false
    BIBLIOTHECARY_PLANNED = true
    URL = 'https://forge.puppet.com'
    COLOR = '#302B6D'

    def self.project_names
      offset = 0
      projects = []
      while true
        results = get_json("https://forgeapi.puppetlabs.com/v3/modules?limit=100&offset=#{offset}")['results'].map { |result| result['slug'] }
	break if results == []
	projects += results
	offset +=100
      end
      projects
    end

    def self.project(name)
      get_json("https://forgeapi.puppetlabs.com/v3/modules/#{name}")
    end

    def self.mapping(project)
      {
        name: project['slug'],
        homepage: "https://forge.puppet.com/#{project['slug']}",
        repository_url: project['current_release']['metadata']['source'],
        description: project['current_release']['metadata']['description'],
        keywords_array: project['current_release']['tags'],
        licenses: project['current_release']['metadata']['license']
      }
    end

    def self.install_instructions(project, version = nil)
      "puppet module install #{project.name}" + (version ? " --version #{version}" : "")
    end
  end
end
