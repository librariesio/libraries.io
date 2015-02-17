class Repositories
  class NuGet < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true

    def self.load_names(limit = nil)
      segment_index = Repositories::NuGet.get_json "http://preview.nuget.org/ver3-ctp1/islatest/segment_index.json"
      segment_count = limit || segment_index['segmentNumber'].to_i - 1

      (0..segment_count).to_a.reverse.each do |number|
        page = Repositories::NuGet.get_json "http://nugetprod0.blob.core.windows.net/ver3-ctp1/islatest/segment_#{number}.json"
        package_ids = page['entry'].map{|entry| entry['id'] }
        package_ids.each { |id| REDIS.sadd 'nuget-names', id }
      end
      puts "Loaded all the names"
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
      latest_version = get_json("https://az320820.vo.msecnd.net/registrations-0/#{project[:name].downcase}/index.json")
      item = latest_version['items'].first['items'].first['catalogEntry']

      {
        name: project[:name],
        description: description(item),
        homepage: item['projectUrl'],
        keywords: item['tags'].join(',')
      }
    end

    def self.description(item)
      item['description'].blank? ? item['summary'] : item['description']
    end

    def self.versions(project)
      latest_version = get_json("https://az320818.vo.msecnd.net/registrations-0/#{project[:name].downcase}/index.json")
      latest_version['items'].first['items'].map do |item|
        {
          number: item['catalogEntry']['version'],
          published_at: item['catalogEntry']['published']
        }
      end
    end
  end
end
