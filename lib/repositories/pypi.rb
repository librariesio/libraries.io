class Repositories
  class Pypi < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    LIBRARIAN_SUPPORT = true
    SECURITY_PLANNED = true
    URL = 'https://pypi.python.org'
    COLOR = '#3581ba'

    def self.project_names
      get_raw("https://pypi.python.org/simple/").scan(/href='(\w+)'/).flatten
    end

    def self.recent_names
      u = 'https://pypi.python.org/pypi?%3Aaction=rss'
      updated = SimpleRSS.parse(Typhoeus.get(u).body).items.map(&:title)
      u = 'https://pypi.python.org/pypi?%3Aaction=packages_rss'
      new_packages = SimpleRSS.parse(Typhoeus.get(u).body).items.map(&:title)
      (updated.map { |t| t.split(' ').first } + new_packages.map { |t| t.split(' ').first }).uniq
    end

    def self.project(name)
      get("https://pypi.python.org/pypi/#{name}/json")
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
  end
end
