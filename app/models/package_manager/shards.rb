module PackageManager
  class Shards < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    LIBRARIAN_SUPPORT = true
    URL = 'https://crystal-shards-registry.herokuapp.com/'
    COLOR = '#776791'

    def self.package_link(project, version = nil)
      "https://crystal-shards-registry.herokuapp.com/shards/#{project.name}"
    end

    def self.project_names
      html = get_html("https://crystal-shards-registry.herokuapp.com/shards")
      html.css('.lead a').map(&:text)
    end

    def self.project(name)
      get("https://crystal-shards-registry.herokuapp.com/api/v1/shards/#{name}")
    end

    def self.mapping(project)
      {
        :name => project["name"],
        :repository_url => repo_fallback(project["url"], nil)
      }
    end
  end
end
