module Repositories
  class Rubygems < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    LIBRARIAN_SUPPORT = true
    SECURITY_PLANNED = true
    URL = 'https://rubygems.org'
    COLOR = '#701516'

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
      versions_response = Gems.versions(project['name'])
      return [] if versions_response.is_a?(String)
      versions_response.map do |v|
        {
          :number => v['number'],
          :published_at => v['created_at']
        }
      end
    end

    def self.update_versions(name)
      p = project(name)
      dbproject = Project.find_by({:name => name, :platform => self.name.demodulize})
      versions(p).each do |version|
        v = dbproject.versions.find_by_number(version[:number])
        v.update_attribute(:published_at, version[:published_at]) if v
      end
      dbproject.save
    end

    def self.dependencies(name, version, _project)
      json = get_json("https://rubygems.org/api/v2/rubygems/#{name}/versions/#{version}.json")

      deps = json['dependencies']
      d = []
      deps['development'].each do |dep|
        d <<  {
          project_name: dep['name'],
          requirements: dep['requirements'],
          kind: 'Development',
          platform: self.name.demodulize
        }
      end
      deps['runtime'].each do |dep|
        d <<  {
          project_name: dep['name'],
          requirements: dep['requirements'],
          kind: 'normal',
          platform: self.name.demodulize
        }
      end
      d
    end
  end
end
