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
    # Adapted from https://peps.python.org/pep-0508/#names to include extras
    PEP_508_NAME_REGEX = /[A-Z0-9][A-Z0-9._-]*[A-Z0-9]|[A-Z0-9]/i
    PEP_508_NAME_WITH_EXTRAS_REGEX = /(^#{PEP_508_NAME_REGEX}\s*(?:\[#{PEP_508_NAME_REGEX}(?:,\s*#{PEP_508_NAME_REGEX})*\])?)/i
    # This is unused but left here for possible future use and so we can quickly reference the set of valid
    # environment markers.
    PEP_508_ENVIRONMENT_MARKERS = %w[
      python_version python_full_version os_name
      sys_platform platform_release platform_system
      platform_version platform_machine platform_python_implementation
      implementation_name implementation_version extra
    ].freeze

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
      (updated.map { |t| t.split.first } + new_packages.map { |t| t.split.first }).uniq
    end

    def self.project(name)
      JsonApiProject.request(project_name: name)
    end

    def self.deprecation_info(db_project)
      json_api_project = project(db_project.name)

      if json_api_project.deprecated?
        # project metadata indicates it is deprecated so return the metadata message
        {
          is_deprecated: true,
          message: json_api_project.deprecation_message,
        }
      else
        # check to see if all the versions have been yanked
        # this is represented by a "Removed" status on mapped versions data
        mapped_versions = versions(json_api_project, nil)

        versions_all_removed = mapped_versions.all? { |v| v[:status] == "Removed" }

        if versions_all_removed
          message = mapped_versions.max_by { |v| v[:published_at] }[:deprecation_reason]

          return {
            is_deprecated: true,
            message: message,
          }
        end

        {
          is_deprecated: false,
          message: nil,
        }
      end
    end

    # mapping eventually receives the return value of the project method.
    # This happens in PackageManager:Base.
    def self.mapping(json_api_project)
      json_api_project.to_mapping
    end

    # versions eventually receives the return value of the project method.
    # This happens in PackageManager::Base.
    def self.versions(json_api_project, _)
      VersionProcessor.new(
        project_releases: json_api_project.releases,
        project_name: json_api_project.name,
        known_versions: known_versions(json_api_project.name)
      ).execute
    end

    def self.one_version(json_api_project, version_number)
      release = json_api_project.releases.find { |r| r.version_number == version_number }
      return nil unless release.present?

      {
        number: version_number,
        published_at: release.published_at,
        original_license: json_api_project.license,
      }
    end

    def self.known_versions(name)
      Project
        .find_by(platform: "Pypi", name: name)
        &.versions
        &.map { |v| v.slice(:number, :published_at, :original_license, :status).symbolize_keys }
        &.index_by { |v| v[:number] } || {}
    end

    # Parses out the name, version requirement, and environment markers from a PEP508 dependency specification
    # https://peps.python.org/pep-0508/
    def self.parse_pep_508_dep_spec(dep)
      name, requirement = dep.split(PEP_508_NAME_WITH_EXTRAS_REGEX, 2).last(2)
      version, environment_markers = requirement.split(";").map(&:strip)

      # remove whitespace from name
      # remove parentheses surrounding version requirement
      [name.remove(/\s/), version&.remove(/[()]/) || "", environment_markers || ""]
    end

    def self.dependencies(name, version, _mapped_project = nil)
      api_response = get("https://pypi.org/pypi/#{name}/#{version}/json")
      deps = api_response.dig("info", "requires_dist") || []
      source_info = api_response.fetch("urls", [])
      Rails.logger.warn("Pypi sdist (no deps): #{name}") unless source_info.any? { |rel| rel["packagetype"] == "bdist_wheel" }

      deps.flat_map do |dep|
        name, version, environment_markers = parse_pep_508_dep_spec(dep)

        {
          project_name: name,
          requirements: version.presence || "*",
          kind: environment_markers.presence || "runtime",
          optional: environment_markers.present?,
          platform: self.name.demodulize,
        }
      end
    end

    def self.project_find_names(project_name)
      [
        project_name,
        project_name.gsub("-", "_"),
        project_name.gsub("_", "-"),
      ]
    end

    # checks to see if the package exists on PyPI and the name matches the canonical name
    def self.canonical_pypi_name?(name)
      json_api_project = project(name)

      json_api_project.present? && json_api_project.name == name
    end
  end
end
