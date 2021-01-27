# frozen_string_literal: true

module PackageManager
  class CocoaPods < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_SUPPORT = true
    URL = "http://cocoapods.org/"
    COLOR = "#438eff"

    def self.package_link(project, _version = nil)
      "http://cocoapods.org/pods/#{project.name}"
    end

    def self.documentation_url(name, version = nil)
      "http://cocoadocs.org/docsets/#{name}/#{version}"
    end

    def self.install_instructions(project, _version = nil)
      "pod try #{project.name}"
    end

    def self.project_names
      get_json("http://cocoapods.libraries.io/pods.json")
    end

    def self.recent_names
      u = "http://cocoapods.libraries.io/feed.rss"
      titles = SimpleRSS.parse(get_raw(u)).items.map(&:title)
      titles.map { |t| t.split(" ")[1] }.uniq
    end

    def self.project(name)
      versions = get_json("http://cocoapods.libraries.io/pods/#{name}.json") || {}
      latest_version = versions.keys.max_by { |version| version.split(".").map(&:to_i) }
      versions.fetch(latest_version, {}).merge("versions" => versions)
    end

    def self.mapping(project)
      {
        name: project["name"],
        description: project["summary"],
        homepage: project["homepage"],
        licenses: parse_license(project["license"]),
        repository_url: repo_fallback(project.dig("source", "git"), ""),
      }
    end

    def self.versions(project, _name)
      project.fetch("versions", {}).keys.map do |v|
        {
          number: v.to_s,
        }
      end
    end

    def self.parse_license(project_license)
      project_license.is_a?(Hash) ? project_license["type"] : project_license
    end
  end
end
