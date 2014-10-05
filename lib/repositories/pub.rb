module Repositories
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
  end
end
