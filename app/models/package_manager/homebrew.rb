# frozen_string_literal: true

module PackageManager
  class Homebrew < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_PLANNED = true
    SECURITY_PLANNED = false
    URL = "http://brew.sh/"
    COLOR = "#555555"

    def self.package_link(db_project, _version = nil)
      "http://formulae.brew.sh/formula/#{db_project.name}"
    end

    def self.install_instructions(db_project, _version = nil)
      "brew install #{db_project.name}"
    end

    def self.project_names
      get("https://formulae.brew.sh/api/formula.json").map { |project| project["name"] }.uniq
    end

    def self.recent_names
      rss = SimpleRSS.parse(get_raw("http://formulae.brew.sh/feed.atom"))
      rss.entries.map { |entry| entry.link.split("/")[-1] }.map { |e| e.split("@").first }.uniq
    end

    def self.project(name)
      get("https://formulae.brew.sh/api/formula/#{name}.json")
    end

    def self.mapping(raw_project)
      MappingBuilder.build_hash(
        name: raw_project["name"],
        description: raw_project["desc"],
        homepage: raw_project["homepage"],
        repository_url: repo_fallback("", raw_project["homepage"]),
        versions: [raw_project.dig("versions", "stable")],
        dependencies: raw_project["dependencies"]
      )
    end

    def self.versions(raw_project, _name)
      stable = raw_project.dig("versions", "stable")
      return [] if stable.blank?

      [
        VersionBuilder.build_hash(
          number: stable
        ),
      ]
    end

    def self.dependencies(_name, version, mapped_project)
      return [] unless version == mapped_project[:versions].first

      mapped_project[:dependencies].map do |dependency|
        {
          project_name: dependency,
          requirements: "*",
          kind: "runtime",
          platform: name.demodulize,
        }
      end
    end
  end
end
