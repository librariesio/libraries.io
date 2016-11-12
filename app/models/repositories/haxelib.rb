module Repositories
  class Haxelib < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    LIBRARIAN_PLANNED = true
    URL = 'https://lib.haxe.org'
    COLOR = '#df7900'

    def self.project_names
      get_html("https://lib.haxe.org/all/").css('.project-list tbody th').map{|th| th.css('a').first.try(:text) }
    end

    def self.recent_names
      u = 'https://lib.haxe.org/rss/'
      titles = SimpleRSS.parse(get_raw(u)).items.map(&:title)
      titles.map { |t| t.split(' ').first }.uniq
    end

    def self.project(name)
      get_json("http://haxelib-json.herokuapp.com/package/#{name}")
    end

    def self.mapping(project)
      {
        name: project['name'],
        keywords_array: project['info']['tags'],
        description: project['info']['desc'],
        licenses: project['info']['license'],
        repository_url: repo_fallback(project['info']['website'], '')
      }
    end

    def self.versions(project)
      project['info']['versions'].map do |version|
        {
          :number => version['name'],
          :published_at => version['date']
        }
      end
    end

  end
end
