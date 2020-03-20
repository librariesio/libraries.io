# frozen_string_literal: true

module PackageManager
  class Wordpress < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    SECURITY_PLANNED = true
    URL = "https://wordpress.org/plugins"
    COLOR = "#4F5D95"

    def self.package_link(project, version = nil)
      "https://wordpress.org/plugins/#{project.name}/#{version}"
    end

    def self.download_url(name, version = nil)
      "https://downloads.wordpress.org/plugin/#{name}.#{version}.zip"
    end

    def self.formatted_name
      "WordPress"
    end

    def self.recent_names
      page = 1
      r = Typhoeus.post "http://api.wordpress.org/plugins/info/1.0/", body: "action=query_plugins&request=O%3A8%3A%22stdClass%22%3A3%3A%7Bs%3A6%3A%22browse%22%3Bs%3A3%3A%22new%22%3Bs%3A8%3A%22per_page%22%3Bi%3A100%3Bs%3A4%3A%22page%22%3Bi%3A#{page}%3B%7D"
      r.body.scan(/"slug";s:[0-9]+:"([^"]+)";/).flatten.compact.uniq
    end

    def self.project_names
      REDIS.smembers "wordpress-names"
    end

    def self.load_names(limit = nil)
      num = REDIS.get("wordpress-page")
      if limit
        REDIS.set "wordpress-page", limit
        num = limit
      elsif num.nil?
        REDIS.set "wordpress-page", 362
        num = 362
      else
        num = num.to_i
      end

      (1..num).to_a.reverse.each do |number|
        r = Typhoeus.post "http://api.wordpress.org/plugins/info/1.0/", body: "action=query_plugins&request=O%3A8%3A%22stdClass%22%3A3%3A%7Bs%3A6%3A%22browse%22%3Bs%3A3%3A%22new%22%3Bs%3A8%3A%22per_page%22%3Bi%3A100%3Bs%3A4%3A%22page%22%3Bi%3A#{number}%3B%7D"
        r.body.scan(/"slug";s:[0-9]+:"([^"]+)";/).flatten.compact.uniq.each do |name|
          REDIS.sadd "wordpress-names", name
        end
        REDIS.set "wordpress-page", number
      end
    end

    def self.project(name)
      get("https://api.wordpress.org/plugins/info/1.0/#{name}.json")
    end

    def self.mapping(project)
      {
        name: project["slug"],
        description: project["short_description"],
        homepage: project["homepage"],
        keywords_array: Array.wrap(project.fetch("tags", {}).values),
        repository_url: repo_fallback("", project["homepage"]),
      }
    end

    def self.versions(project, _name)
      [
        {
          number: project["version"],
          published_at: project["last_updated"],
        },
      ]
    end
  end
end
