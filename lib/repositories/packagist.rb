class Repositories
  class Packagist < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    URL = 'https://packagist.org'

    def self.project_names
      get("https://packagist.org/packages/list.json")['packageNames']
    end

    def self.recent_names
      u = 'https://packagist.org/feeds/releases.rss'
      updated = SimpleRSS.parse(Typhoeus.get(u).body).items.map(&:title)
      u = 'https://packagist.org/feeds/packages.rss'
      new_packages = SimpleRSS.parse(Typhoeus.get(u).body).items.map(&:title)
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
        :keywords => latest_version['keywords'].join(','),
        :licenses => latest_version['license'].join(','),
        :repository_url => repo_fallback(project['repository'],latest_version['home_page'])
      }
    end

    def self.versions(project)
      project['versions'].map do |k, v|
        {
          :number => k,
          :published_at => v['time']
        }
      end
    end
  end
end
