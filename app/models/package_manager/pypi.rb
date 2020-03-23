# frozen_string_literal: true

module PackageManager
  class Pypi < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    SECURITY_PLANNED = true
    URL = "https://pypi.org/"
    COLOR = "#3572A5"

    def self.package_link(project, version = nil)
      "https://pypi.org/project/#{project.name}/#{version}"
    end

    def self.install_instructions(project, version = nil)
      "pip install #{project.name}" + (version ? "==#{version}" : "")
    end

    def self.formatted_name
      "PyPI"
    end

    def self.project_names
      index = Nokogiri::HTML(get_raw("https://pypi.org/simple/"))
      index.css("a").map(&:text)
    end

    def self.recent_names
      u = "https://pypi.org/rss/updates.xml"
      updated = SimpleRSS.parse(get_raw(u)).items.map(&:title)
      u = "https://pypi.org/rss/packages.xml"
      new_packages = SimpleRSS.parse(get_raw(u)).items.map(&:title)
      (updated.map { |t| t.split(" ").first } + new_packages.map { |t| t.split(" ").first }).uniq
    end

    def self.project(name)
      get("https://pypi.org/pypi/#{name}/json")
    rescue StandardError
      {}
    end

    def self.mapping(project)
      {
        name: project["info"]["name"],
        description: project["info"]["summary"],
        homepage: project["info"]["home_page"],
        keywords_array: Array.wrap(project["info"]["keywords"].try(:split, ",")),
        licenses: licenses(project),
        repository_url: repo_fallback(
          project.dig("info", "project_urls", "Source").presence || project.dig("info", "project_urls", "Source Code"),
          project["info"]["home_page"].presence || project.dig("info", "project_urls", "Homepage")
        ),
      }
    end

    def self.versions(project, name)
      project["releases"].reject { |_k, v| v == [] }.map do |k, v|
        release = get("https://pypi.org/pypi/#{name}/#{k}/json")
        {
          number: k,
          published_at: v[0]["upload_time"],
          original_license: release.dig("info", "license"),
        }
      end
    end

    def self.dependencies(name, version, _project)
      deps = get("http://pip.libraries.io/#{name}/#{version}.json")
      return [] if deps.is_a?(Hash) && deps["error"].present?

      deps.map do |dep|
        {
          project_name: dep["name"],
          requirements: dep["requirements"] || "*",
          kind: "runtime",
          optional: false,
          platform: self.name.demodulize,
        }
      end
    end

    def self.licenses(project)
      return project["info"]["license"] if project["info"]["license"].present?

      license_classifiers = project["info"]["classifiers"].select { |c| c.start_with?("License :: ") }
      license_classifiers.map { |l| l.split(":: ").last }.join(",")
    end

    def self.project_find_names(project_name)
      [
        project_name,
        project_name.gsub("-", "_"),
        project_name.gsub("_", "-"),
      ]
    end
  end
end
