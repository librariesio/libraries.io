module PackageManager
  class Pypi < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    SECURITY_PLANNED = true
    URL = 'https://pypi.org/'
    COLOR = '#3572A5'

    def self.package_link(project, version = nil)
      "https://pypi.org/project/#{project.name}/#{version}"
    end

    def self.install_instructions(project, version = nil)
      "pip install #{project.name}" + (version ? "==#{version}" : "")
    end

    def self.formatted_name
      'PyPI'
    end

    def self.project_names
      get_raw("https://pypi.org/simple/").scan(/href='(\w+)'/).flatten
    end

    def self.recent_names
      u = 'https://pypi.org/rss/updates.xml'
      updated = SimpleRSS.parse(get_raw(u)).items.map(&:title)
      u = 'https://pypi.org/rss/packages.xml'
      new_packages = SimpleRSS.parse(get_raw(u)).items.map(&:title)
      (updated.map { |t| t.split(' ').first } + new_packages.map { |t| t.split(' ').first }).uniq
    end

    def self.project(name)
      get("https://pypi.org/pypi/#{name}/json")
    rescue
      {}
    end

    def self.mapping(project)
      {
        :name => project['info']['name'],
        :description => project['info']['summary'],
        :homepage => project['info']['home_page'],
        :keywords_array => Array.wrap(project['info']['keywords'].try(:split, ',')),
        :licenses => project['info']['license'],
        :repository_url => repo_fallback('', project['info']['home_page'])
      }
    end

    def self.versions(project)
      project['releases'].select{ |k, v| v != [] }.map do |k, v|
        {
          :number => k,
          :published_at => v[0]['upload_time']
        }
      end
    end

    def self.dependencies(name, version, _project)
      deps = get("http://pip.libraries.io/#{name}/#{version}.json")
      return [] if deps.is_a?(Hash) && deps['error'].present?

      deps.map do |dep|
        {
          project_name: dep['name'],
          requirements: dep['requirements'] || '*',
          kind: 'runtime',
          optional: false,
          platform: self.name.demodulize
        }
      end
    end
  end
end
