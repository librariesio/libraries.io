# frozen_string_literal: true

module PackageManager
  class Hackage < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_SUPPORT = true
    URL = "http://hackage.haskell.org"
    COLOR = "#29b544"

    def self.package_link(project, version = nil)
      "http://hackage.haskell.org/package/#{project.name}" + (version ? "-#{version}" : "")
    end

    def self.download_url(name, version = nil)
      "http://hackage.haskell.org/package/#{name}-#{version}/#{name}-#{version}.tar.gz"
    end

    def self.install_instructions(project, version = nil)
      "cabal install #{project.name}" + (version ? "-#{version}" : "")
    end

    def self.project_names
      get_json("http://hackage.haskell.org/packages/").map { |h| h["packageName"] }
    end

    def self.recent_names
      u = "http://hackage.haskell.org/packages/recent.rss"
      titles = SimpleRSS.parse(get_raw(u)).items.map(&:title)
      titles.map { |t| t.split(" ").first }.uniq
    end

    def self.project(name)
      {
        name: name,
        page: get_html("http://hackage.haskell.org/package/#{name}"),
      }
    end

    def self.mapping(raw_project)
      {
        name: raw_project[:name],
        keywords_array: Array(raw_project[:page].css("#content div:first a")[1..-1].map(&:text)),
        description: description(raw_project[:page]),
        licenses: find_attribute(raw_project[:page], "License"),
        homepage: find_attribute(raw_project[:page], "Home page"),
        repository_url: repo_fallback(repository_url(find_attribute(raw_project[:page], "Source repository")), find_attribute(raw_project[:page], "Home page")),
      }
    end

    def self.versions(raw_project, _name)
      versions = find_attribute(raw_project[:page], "Versions")
      versions = find_attribute(raw_project[:page], "Version") if versions.nil?
      versions.delete("(info)").split(",").map(&:strip).map do |v|
        {
          number: v,
        }
      end
    end

    def self.find_attribute(page, name)
      tr = page.css("#content tr").select { |t| t.css("th").text.to_s.start_with?(name) }.first
      tr&.css("td")&.text
    end

    def self.description(page)
      contents = page.css("#content p, #content hr").map(&:text)
      index = contents.index ""
      return "" unless index

      contents[0..(index - 1)].join("\n\n")
    end

    def self.repository_url(text)
      return nil unless text.present?

      match = text.match(/github.com\/(.+?)\.git/)
      return nil unless match

      "https://github.com/#{match[1]}"
    end
  end
end
