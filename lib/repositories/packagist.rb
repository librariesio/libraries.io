class Repositories
  class Packagist < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false

    def self.project_names
      get("https://packagist.org/packages/list.json")['packageNames']
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
        :licenses => latest_version['license'].join(',')
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
