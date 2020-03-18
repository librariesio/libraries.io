# frozen_string_literal: true

module PackageManager
  class Racket < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_SUPPORT = false
    URL = "http://pkgs.racket-lang.org/"
    COLOR = "#375eab"

    def self.package_link(project, _version = nil)
      "http://pkgs.racket-lang.org/package/#{project.name}"
    end

    def self.project_names
      get_raw("http://pkgs.racket-lang.org/pkgs")[2..-3].split('" "')
    end

    def self.project(name)
      {
        name: name,
        page: get_html("http://pkgs.racket-lang.org/package/#{name}"),
      }
    end

    def self.mapping(project)
      {
        name: project[:name],
        repository_url: project[:page].at('a:contains("Code")')&.attributes.try(:[], "href")&.text,
        description: project[:page].css(".jumbotron p")&.first&.children&.first&.text,
        homepage: homepage_link(project[:page]).present? ? homepage_link(project[:page]).attributes["href"].value : "",
        keywords_array: project[:page].at('th:contains("Tags")').parent.css("a")&.map { |el| el.children.first.try(:text) },
      }
    end

    def self.homepage_link(page)
      page.at('a:contains("Code")') || page.at('th:contains("Documentation")').parent.css("a").first
    end
  end
end
