class Repositories
  class Pypi < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    URL = 'https://pypi.python.org'

    def self.project_names
      get_raw("https://pypi.python.org/simple/").scan(/href='(\w+)'/).flatten
    end

    def self.project(name)
      get("https://pypi.python.org/pypi/#{name}/json")
    end

    def self.mapping(project)
      {
        :name => project['info']['name'],
        :description => project['info']['summary'],
        :homepage => project['info']['home_page'],
        :keywords => project['info']['keywords'],
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
