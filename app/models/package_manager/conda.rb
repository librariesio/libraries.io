# frozen_string_literal: true

module PackageManager
  class Conda < MultipleSourcesBase
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    REPOSITORY_SOURCE_NAME = "Main"
    BIBLIOTHECARY_SUPPORT = true
    SUPPORTS_SINGLE_VERSION_UPDATE = true
    URL = "https://anaconda.org"
    API_URL = "https://conda.libraries.io"

    def self.formatted_name
      "conda"
    end

    def self.db_platform
      "Conda"
    end

    def self.project_names
      get_json("#{API_URL}/packages").keys
    end

    def self.all_projects
      get_json("#{API_URL}/packges")
    end

    def self.one_version(name, version_string)
      get_json("#{API_URL}/#{self::REPOSITORY_SOURCE_NAME}/#{name}/#{version_string}")&.first
    end

    def self.project(name)
      get_json("#{API_URL}/#{self::REPOSITORY_SOURCE_NAME}/#{name}")
    end

    def self.recent_names
      last_update = Version.where(project: Project.where(platform: "Conda")).select(:updated_at).order(updated_at: :desc).limit(1).first&.updated_at
      packages = get_json("#{API_URL}/#{self::REPOSITORY_SOURCE_NAME}/")

      return packages.keys if last_update.nil?

      packages.keys.filter do |name|
        packages[name]["versions"].any? { |version| version["published_at"].is_a?(String) && Time.parse(version["published_at"]) > last_update }
      end
    end

    def self.download_url(name, version = nil)
      project = Project.find_by(name: name, platform: db_platform)
      db_version = project.versions.find_by(number: version)
      repository_source = db_version&.repository_sources&.first.presence || "default"
      if version.present?
        get_json("#{API_URL}/#{repository_source}/#{name}/#{version}")&.first&.dig("download_url")
      else
        get_json("#{API_URL}/#{repository_source}/#{name}")&.first&.dig("download_url")
      end
    end

    def self.package_link(project, _version = nil)
      project = Project.find_by(name: name, platform: db_platform)
      db_version = project.versions.find_by(number: version)
      repository_source = db_version&.repository_sources&.first.presence || "default"
      PROVIDER_MAP[repository_source].package_link
    end

    def self.install_instructions(project, _version = nil)
      project = Project.find_by(name: name, platform: db_platform)
      db_version = project.versions.find_by(number: version)
      repository_source = db_version&.repository_sources&.first.presence || "default"
      PROVIDER_MAP[repository_source].install_instructions
    end

    PROVIDER_MAP = {
      "CondaForge" => Forge,
      "default" => Main,
      "CondaMain" => Main,
    }.freeze

    def self.providers(project)
      project
        .versions
        .flat_map(&:repository_sources)
        .compact
        .uniq
        .map { |source| PROVIDER_MAP[source] } || [PROVIDER_MAP["default"]]
    end

    def self.check_status_url(project)
      "#{API_URL}/package/#{project.name}"
    end

    def self.mapping(project)
      # TODO: can we make this more explicit?
      project.deep_symbolize_keys
    end

    def self.versions(project, _name)
      project["versions"].map { |version| version.deep_symbolize_keys.slice(:number, :original_license, :published_at) }
    end

    def self.dependencies(name, version, _mapped_project)
      version_data = get_json("#{API_URL}/package/#{name}")["versions"]
      deps = version_data.find { |item| item["number"] == version }&.dig("dependencies")&.map { |d| d.split(" ") }
      map_dependencies(deps, "runtime")
    end
  end
end
