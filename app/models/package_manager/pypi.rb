# frozen_string_literal: true

module PackageManager
  class Pypi < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    SECURITY_PLANNED = true
    URL = "https://pypi.org/"
    COLOR = "#3572A5"
    ENTIRE_PACKAGE_CAN_BE_DEPRECATED = true

    def self.package_link(project, version = nil)
      "https://pypi.org/project/#{project.name}/#{version}"
    end

    def self.check_status_url(project)
      "https://pypi.org/pypi/#{project.name}/json/"
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

    def self.deprecation_info(name)
      p = project(name)
      last_version = p["releases"].values.last&.first

      is_deprecated, message = if last_version && last_version["yanked"] == true
        # PEP-0423: newer way of deleting specific versions (https://www.python.org/dev/peps/pep-0592/)
        [true, last_version["yanked_reason"]]
      elsif p.fetch("info", {}).fetch("classifiers", []).include?("Development Status :: 7 - Inactive")
        # PEP-0423: older way of renaming/deprecating a project (https://www.python.org/dev/peps/pep-0423/#how-to-rename-a-project)
        [true, "Development Status :: 7 - Inactive"]
      else
        [false, nil]
      end

      {
        is_deprecated: is_deprecated,
        message: message,
      }
    end

    def self.mapping(project)
      {
        name: project["info"]["name"],
        description: project["info"]["summary"],
        homepage: project["info"]["home_page"],
        keywords_array: Array.wrap(project["info"]["keywords"].try(:split, /[\s.,]+/)),
        licenses: licenses(project),
        repository_url: repo_fallback(
          project.dig("info", "project_urls", "Source").presence || project.dig("info", "project_urls", "Source Code"),
          project["info"]["home_page"].presence || project.dig("info", "project_urls", "Homepage")
        ),
      }
    end

    def self.versions(project, name)
      return [] if project.nil?
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
      api_response = get("https://pypi.org/pypi/#{name}/#{version}/json")
      deps = api_response.dig("info", "requires_dist")
      source_info = api_response.dig("releases", version)
      Rails.logger.warn("Pypi sdist (no deps): #{name}") unless source_info.any? { |rel| rel["packagetype"] == "bdist_wheel" }

      deps.map do |dep|
        name, version = dep.split
        {
          project_name: name,
          requirements: (version.nil? || version == ";") ? "*": version.gsub(/\(|\)/,""),
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
