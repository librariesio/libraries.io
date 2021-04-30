# frozen_string_literal: true

module PackageManager
  class Sublime < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    URL = "https://packagecontrol.io"
    COLOR = "#3572A5"

    def self.package_link(project, _version = nil)
      "https://packagecontrol.io/packages/#{project.name}"
    end

    def self.project_names
      get("https://packagecontrol.io/channel.json")["packages_cache"].map { |_k, v| v[0]["name"] }
    end

    def self.project(name)
      Faraday.new("https://packagecontrol.io/packages/#{URI.escape(name)}.json")
        .get
        .then { |resp| resp.status == 200 ? Oj.load(resp.body) : nil }
    end

    def self.mapping(raw_project)
      {
        name: raw_project["name"],
        description: raw_project["description"],
        homepage: raw_project["homepage"],
        repository_url: repo_fallback(parse_repo(raw_project["issues"]), raw_project["homepage"]),
        keywords_array: Array.wrap(raw_project["labels"]),
      }
    end

    def self.versions(raw_project, _name)
      raw_project["versions"].map do |v|
        {
          number: v["version"],
        }
      end
    end

    def self.parse_repo(url)
      return nil unless url

      url.gsub(/\/issues(\/)?/i, "")
    end
  end
end
