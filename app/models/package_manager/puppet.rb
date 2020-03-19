module PackageManager
  class Puppet < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
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
      current_release = project['current_release']
      metadata = current_release['metadata']
      {
        name: project['slug'],
        repository_url: metadata['source'],
        description: metadata['description'],
        keywords_array: current_release['tags'],
        licenses: metadata['license']
      }
    end

    def self.versions(project, name)
      project['releases'].map do |release|
        {
          number: release['version'],
          published_at: release['created_at']
        }
      end
    end

    def self.dependencies(name, version, _project)
      release = get_json("https://forgeapi.puppetlabs.com/v3/releases/#{name}-#{version}")
      metadata = release['metadata']
      metadata['dependencies'].map do |dependency|
        {
          project_name: dependency['name'].sub('/', '-'),
          requirements: dependency['version_requirement'],
          kind: 'runtime',
          platform: self.name.demodulize
        }
      end
    end

    def self.recent_names
      get_json("https://forgeapi.puppetlabs.com/v3/modules?limit=100&sort_by=latest_release")['results'].map { |result| result['slug'] }
    end

    def self.install_instructions(project, version = nil)
      "puppet module install #{project.name}" + (version ? " --version #{version}" : "")
    end

    def self.package_link(project, version = nil)
      "https://forge.puppet.com/#{project.name.sub('-', '/')}" + (version ? "/#{version}" : "")
    end

    def self.download_url(name, version = nil)
      "https://forge.puppet.com/v3/files/#{name}-#{version}.tar.gz"
    end
  end
end
