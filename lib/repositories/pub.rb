class Repositories
  class Pub
    def self.project_names
      page = 1
      projects = []
      while true
        r = HTTParty.get("https://pub.dartlang.org/api/packages?page=#{page}").parsed_response
        break if r['packages'] == []
        projects += r['packages']
        page +=1
      end
      projects.map{|project| project['name'] }.sort
    end

    def self.project(name)
      HTTParty.get("https://pub.dartlang.org/api/packages/#{name}").parsed_response
    end

    def self.keys
      ["uploaders", "name", "versions", "url", "uploaders_url", "created", "new_version_url", "version_url", "downloads", "latest"]
    end

    def self.mapping(project)
      {
        :name => project["name"],
        :homepage => project["url"],
        :published_at => project["created"],
      }
    end

    # TODO repo, authors, versions
  end
end
