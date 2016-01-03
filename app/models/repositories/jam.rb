module Repositories
  class Jam < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    SECURITY_PLANNED = true
    URL = 'http://jamjs.org/'
    COLOR = '#f1e05a'

    def self.project_names
      projects.keys.sort
    end

    def self.projects
      @projects ||= begin
        prjcts = {}
        packages = get_json("http://jamjs.org/repository/_design/jam-packages/_view/packages_by_category?reduce=false&include_docs=true&startkey=%5B%22All%22%5D&endkey=%5B%22All%22%2C%7B%7D%5D&limit=2000&skip=0")['rows']

        packages.each do |package|
          prjcts[package['id'].downcase] = package['doc']
        end

        prjcts
      end
    end

    def self.project(name)
      get("http://jamjs.org/repository/#{name}")
    end

    def self.mapping(project)
      return false unless project["versions"].present?
      latest_version = project["versions"].to_a.last[1]
      {
        :name => project["name"],
        :description => project["description"],
        :homepage => project["homepage"],
        :keywords_array => Array.wrap(project.fetch("keywords", [])),
        :licenses => latest_version.fetch('licenses', []).map{|l| l['type'] }.join(','),
        :repository_url => repo_fallback(latest_version.fetch('repository', {})['url'],project["homepage"])
      }
    end

    def self.versions(project)
      project['time'].except("modified", "created").map do |k,v|
        {
          :number => k,
          :published_at => v
        }
      end
    end
  end
end
