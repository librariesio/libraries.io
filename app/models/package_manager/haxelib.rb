# frozen_string_literal: true

module PackageManager
  class Haxelib < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    URL = "https://lib.haxe.org"
    COLOR = "#df7900"

    def self.package_link(db_project, version = nil)
      "https://lib.haxe.org/p/#{db_project.name}/#{version}"
    end

    def self.download_url(db_project, version = nil)
      "https://lib.haxe.org/p/#{db_project.name}/#{version}/download/"
    end

    def self.install_instructions(db_project, version = nil)
      "haxelib install #{db_project.name} #{version}"
    end

    def self.project_names
      get_html("https://lib.haxe.org/all/").css(".project-list tbody th").map { |th| th.css("a").first.try(:text) }
    end

    def self.recent_names
      u = "https://lib.haxe.org/rss/"
      titles = SimpleRSS.parse(get_raw(u)).items.map(&:title)
      titles.map { |t| t.split.first }.uniq
    end

    def self.project(name)
      get_json("http://haxelib-json.herokuapp.com/package/#{name}")
    end

    def self.mapping(raw_project)
      {
        name: raw_project["name"],
        keywords_array: raw_project["info"]["tags"],
        description: raw_project["info"]["desc"],
        licenses: raw_project["info"]["license"],
        repository_url: repo_fallback(raw_project["info"]["website"], ""),
      }
    end

    def self.versions(raw_project, _name)
      raw_project["info"]["versions"].map do |version|
        {
          number: version["name"],
          published_at: version["date"],
        }
      end
    end

    def self.dependencies(name, version, _mapped_project)
      json = get_json("https://lib.haxe.org/p/#{name}/#{version}/raw-files/haxelib.json")
      return [] unless json["dependencies"]

      json["dependencies"].map do |dep_name, dep_version|
        {
          project_name: dep_name,
          requirements: dep_version.empty? ? "*" : dep_version,
          kind: "runtime",
          platform: self.name.demodulize,
        }
      end
    rescue StandardError
      []
    end
  end
end
