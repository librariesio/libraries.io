module PackageManager
  class Packagist < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    LIBRARIAN_SUPPORT = true
    SECURITY_PLANNED = true
    URL = 'https://packagist.org'
    COLOR = '#4F5D95'

    def self.package_link(project, version = nil)
      "https://packagist.org/packages/#{project.name}##{version}"
    end

    def self.project_names
      get("https://packagist.org/packages/list.json")['packageNames']
    end

    def self.recent_names
      u = 'https://packagist.org/feeds/releases.rss'
      updated = SimpleRSS.parse(get_raw(u)).items.map(&:title)
      u = 'https://packagist.org/feeds/packages.rss'
      new_packages = SimpleRSS.parse(get_raw(u)).items.map(&:title)
      (updated.map { |t| t.split(' ').first } + new_packages).uniq
    end

    def self.project(name)
      get("https://packagist.org/packages/#{name}.json")['package']
    end

    def self.mapping(project)
      return false unless project["versions"].any?
      latest_version = project["versions"].to_a.last[1]
      {
        :name =>  latest_version['name'],
        :description => latest_version['description'],
        :homepage => latest_version['home_page'],
        :keywords_array => Array.wrap(latest_version['keywords']),
        :licenses => latest_version['license'].join(','),
        :repository_url => repo_fallback(project['repository'],latest_version['home_page'])
      }
    end

    def self.versions(project)
      acceptable_versions(project).map do |k, v|
        {
          :number => k,
          :published_at => v['time']
        }
      end
    end

    def self.acceptable_versions(project)
      project['versions'].select do |k, _v|
        (k =~ /^dev-.*/i).nil?
      end
    end

    def self.dependencies(name, version, _project)
      vers = project(name)['versions'][version]
      return [] if vers.nil?
      map_dependencies(vers.fetch('require', {}).reject{|k,_v| k == 'php' }, 'normal') +
      map_dependencies(vers.fetch('require-dev', {}).reject{|k,_v| k == 'php' }, 'Development')
    end
  end
end
