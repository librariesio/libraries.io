class Repositories
  class NuGet < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    LIBRARIAN_SUPPORT = true
    URL = 'https://www.nuget.org'
    COLOR = '#178600'

    def self.load_names(limit = nil)
      endpoints = name_endpoints
      segment_count = limit || endpoints.length - 1

      endpoints.reverse[0..segment_count].each do |endpoint|
        package_ids = get_names(endpoint)
        package_ids.each { |id| REDIS.sadd 'nuget-names', id }
      end
      puts "Loaded all the names"
    end

    def self.recent_names
      name_endpoints.reverse[0..2].map{|url| get_names(url) }.flatten.uniq
    end

    def self.name_endpoints
      get('https://api.nuget.org/v3/catalog0/index.json')['items'].map{|i| i['@id']}
    end

    def self.get_names(endpoint)
      get(endpoint)['items'].map{|i| i["nuget:id"]}
    end

    def self.project_names
      REDIS.smembers 'nuget-names'
    end

    def self.project(name)
      h = {
        name: name
      }
      h[:versions] = versions(h)
      h
    end

    def self.mapping(project)
      latest_version = get_json("https://api.nuget.org/v3/registration1/#{project[:name].downcase}/index.json")
      item = latest_version['items'].last['items'].last['catalogEntry']

      {
        name: project[:name],
        description: description(item),
        homepage: item['projectUrl'],
        keywords_array: Array(item['tags']),
        repository_url: repo_fallback('', item['projectUrl'])
      }
    end

    def self.description(item)
      item['description'].blank? ? item['summary'] : item['description']
    end

    def self.versions(project)
      latest_version = get_json("https://api.nuget.org/v3/registration1/#{project[:name].downcase}/index.json")
      latest_version['items'].first['items'].map do |item|
        {
          number: item['catalogEntry']['version'],
          published_at: item['catalogEntry']['published']
        }
      end
    end
  end
end
