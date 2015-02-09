class Repositories
  class Rubygems < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    URL = 'https://rubygems.org'

    def self.project_names
      gems = Marshal.load(Gem.gunzip(get_raw("http://production.cf.rubygems.org/specs.4.8.gz")))
      gems.map(&:first).uniq
    end

    def self.recent_names
      updated = get('https://rubygems.org/api/v1/activity/just_updated.json').map{|h| h['name']}
      new_gems = get('https://rubygems.org/api/v1/activity/latest.json').map{|h| h['name']}
      (updated + new_gems).uniq
    end

    def self.project(name)
      Gems.info name
    end

    def self.mapping(project)
      {
        :name => project["name"],
        :description => project["info"],
        :homepage => project["homepage_uri"],
        :licenses => project.fetch("licenses", []).try(:join, ','),
        :repository_url => repo_fallback(project['source_code_uri'],project["homepage_uri"])
      }
    end

    def self.versions(project)
      Gems.versions(project['name']).map do |v|
        {
          :number => v['number'],
          :published_at => v['built_at']
        }
      end
    end
  end
end
