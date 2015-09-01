class Repositories
  class Biicode < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    LIBRARIAN_PLANNED = true
    URL = 'https://www.biicode.com/'
    COLOR = '#f34b7d'

    def self.name
      'biicode'
    end

    def self.project_names
      get("https://webapi.biicode.com/v1/misc/blocks")['blocks']
    end

    def self.project(name)
      json = get_raw("https://webapi.biicode.com/v1/misc/blocks/#{name}")+'}'
      Oj.load(json)
    end

    def self.mapping(project)
      {
        :name => project['name'],
        :description => project['description']
      }
    end

    def self.versions(project)
      project['versions'].map do |version|
        {
          :number => version.keys.first,
          :published_at => version.values.first
        }
      end
    end

    def self.dependencies(name, version)
      deps = get("https://webapi.biicode.com/v1/misc/deps/#{name}/#{version}")
      deps.map do |dep|
        {
          project_name: dep['name'],
          requirements: dep['version'],
          kind: 'normal',
          optional: false,
          platform: self.name.demodulize
        }
      end
    end
  end
end
