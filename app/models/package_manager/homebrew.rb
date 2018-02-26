module PackageManager
  class Homebrew < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_PLANNED = true
    SECURITY_PLANNED = false
    URL = 'http://brew.sh/'
    COLOR = '#555555'

    def self.package_link(project, version = nil)
      "http://formulae.brew.sh/formula/#{project.name}"
    end

    def self.install_instructions(project, version = nil)
      "brew install #{project.name}"  + (version ? "@#{version}" : '')
    end

    def self.project_names
      get("http://brewformulas.org/?format=json").map{|project| project['formula'] }.uniq
    end

    def self.recent_names
      rss = SimpleRSS.parse(get_raw('http://formulae.brew.sh/feed.atom'))
      rss.entries.map{ |entry| entry.link.split('/')[-1] }.map{|e| e.split('@').first }.uniq
    end

    def self.project(name)
      JSON.parse(`brew info #{name} --json=v1`).first
    end

    def self.mapping(project)
      {
        :name => project['full_name'],
        :description => project['desc'],
        :homepage => project['homepage'],
      }
    end

    def self.versions(project)
      project['installed'].map do |item|
        {
          number: item['version']
        }
      end
    end

    def self.dependencies(name, version, project)
      project['installed'].select{ |version_info| version_info['version'] == version }.first['runtime_dependencies'].map do |dependency|
        {
          project_name: dependency['full_name'],
          requirements: dependency['version'],
          kind: 'runtime',
        }
      end
    end
  end
end
