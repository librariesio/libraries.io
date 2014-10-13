class Repositories
  class Sublime < Base
    def self.project_names
      HTTParty.get("https://sublime.wbond.net/channel.json").parsed_response['packages_cache'].map{|k,v| v[0]['name']}
    end

    def self.project(name)
      HTTParty.get(URI.escape("https://sublime.wbond.net/packages/#{name}.json")).parsed_response
    end

    def self.mapping(project)
      {
        :name => project["name"],
        :description => project["description"],
        :homepage => project["homepage"],
        :keywords => project["labels"].join(',')
      }
    end

    # TODO repo, authors, versions
  end
end
