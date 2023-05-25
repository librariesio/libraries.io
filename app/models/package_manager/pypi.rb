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
    SUPPORTS_SINGLE_VERSION_UPDATE = true
    PYPI_PRERELEASE = /(a|b|rc|dev)[0-9]+$/.freeze
    # Adapted from https://peps.python.org/pep-0508/#names
    PEP_508_NAME_REGEX = /^([A-Z0-9][A-Z0-9._-]*[A-Z0-9]|[A-Z0-9])/i.freeze

    def self.package_link(db_project, version = nil)
      # NB PEP 503: "All URLs which respond with an HTML5 page MUST end with a / and the repository SHOULD redirect the URLs without a / to add a / to the end."
      "https://pypi.org/project/#{db_project.name}/"
        .then { |url| version.present? ? url + "#{version}/" : url }
    end

    def self.check_status_url(db_project)
      # NB Pypa has maintained the original JSON API behavior of allowing no trailing slash in python/pypi-infra/pull/74
      "https://pypi.org/pypi/#{db_project.name}/json"
    end

    def self.install_instructions(db_project, version = nil)
      "pip install #{db_project.name}" + (version ? "==#{version}" : "")
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

    def self.deprecation_info(db_project)
      p = project(db_project.name)
      last_version = p["releases"].reject { |version, _releases| version =~ PYPI_PRERELEASE }.values.last&.first

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

    def self.select_repository_url(raw_project)
      ["Source", "Source Code", "Repository", "Code"].filter_map do |field|
        raw_project.dig("info", "project_urls", field)
      end.first
    end

    def self.select_homepage_url(raw_project)
      raw_project["info"]["home_page"].presence ||
        raw_project.dig("info", "project_urls", "Homepage")
    end

    def self.mapping(raw_project)
      {
        name: raw_project["info"]["name"],
        description: raw_project["info"]["summary"],
        homepage: raw_project["info"]["home_page"],
        keywords_array: Array.wrap(raw_project["info"]["keywords"].try(:split, /[\s.,]+/)),
        licenses: licenses(raw_project),
        repository_url: repo_fallback(
          select_repository_url(raw_project),
          select_homepage_url(raw_project)
        ),
      }
    end

    def self.versions(raw_project, name)
      return [] if raw_project.nil?

      known = known_versions(name)

      raw_project["releases"].reject { |_k, v| v == [] }.map do |k, v|
        if known.key?(k)
          known[k]
        else
          release = get("https://pypi.org/pypi/#{name}/#{k}/json")

          {
            number: k,
            published_at: v[0]["upload_time"],
            original_license: release.dig("info", "license"),
          }
        end
      end
    end

    def self.one_version(raw_project, version_string)
      release = get("https://pypi.org/pypi/#{raw_project['info']['name']}/#{version_string}/json")
      return nil unless release.present?

      {
        number: version_string,
        published_at: release.dig("releases", version_string, 0, "upload_time"),
        original_license: release.dig("info", "license"),
      }
    end

    def self.known_versions(name)
      Project
        .find_by(platform: "Pypi", name: name)
        &.versions
        &.map { |v| v.slice(:number, :published_at, :original_license).symbolize_keys }
        &.index_by { |v| v[:number] } || {}
    end

    # Simply parses out the name of a PEP 508 Dependency specification: https://peps.python.org/pep-0508/
    # Leaves the rest as-is with any leading semicolons or spaces stripped
    def self.parse_pep_508_dep_spec(dep)
      name, requirement = dep.split(PEP_508_NAME_REGEX, 2).last(2).map(&:strip)
      requirement = requirement.sub(/^[\s;]*/, "")
      [name, requirement]
    end

    def self.parse_requirement_extras(requirements)
      parsed = requirements
                 .split(/(?:or )?extra\s*==/)
                 .map { |part| part.delete("'\"\\ ;") }

      (requirement, *extras) = parsed

      [requirement, extras]
    end

    def self.dependencies(name, version, _mapped_project = nil)
      api_response = get("https://pypi.org/pypi/#{name}/#{version}/json")
      deps = api_response.dig("info", "requires_dist") || []
      source_info = api_response.fetch("urls", [])
      Rails.logger.warn("Pypi sdist (no deps): #{name}") unless source_info.any? { |rel| rel["packagetype"] == "bdist_wheel" }

      deps.flat_map do |dep|
        dep_name, requirements = parse_pep_508_dep_spec(dep)
        requirement, extras = parse_requirement_extras(requirements)

        mapped_dep = {
          project_name: dep_name,
          requirements: requirement.blank? ? "*" : requirement,
          optional: false,
          platform: self.name.demodulize,
        }

        if extras.present?
          extras.map do |extra|
            mapped_dep.merge(kind: extra)
          end
        else
          mapped_dep.merge(kind: "runtime")
        end
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

    # checks to see if the package exists on PyPI and the name matches the canonical name
    def self.has_canonical_pypi_name?(name)
      raw_project = project(name)
      return false unless raw_project.present?

      mapped_project = mapping(raw_project)
      # did we get a response from PyPI and does the name it respond with match the name passed in
      mapped_project[:name] == name
    end
  end
end
