# frozen_string_literal: true

module PackageManager
  class Conda < MultipleSourcesBase
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    REPOSITORY_SOURCE_NAME = "Main"
    URL = "https://anaconda.org"
    API_URL = "https://conda.libraries.io"

    PROVIDER_MAP = ProviderMap.new(prioritized_provider_infos: [
      ProviderInfo.new(identifier: "Main", default: true, provider_class: Main),
      ProviderInfo.new(identifier: "CondaMain", provider_class: Main),
      ProviderInfo.new(identifier: "CondaForge", provider_class: Forge),
    ])

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
      get_json("#{API_URL}/packages")
    end

    def self.one_version(raw_project, version_string)
      get_json("#{API_URL}/#{self::REPOSITORY_SOURCE_NAME}/#{raw_project['name']}/#{version_string}")&.first
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

    def self.download_url(db_project, version = nil)
      db_version = db_project.versions.find_by(number: version)
      repository_source = db_version&.repository_sources&.first.presence || "default"
      if version.present?
        get_json("#{API_URL}/#{repository_source}/#{db_project.name}/#{version}")&.first&.dig("download_url")
      else
        get_json("#{API_URL}/#{repository_source}/#{db_project.name}")&.first&.dig("download_url")
      end
    end

    def self.install_instructions(db_project, _version = nil)
      self::PROVIDER_MAP
        .preferred_provider_for_project(project: db_project)
        .provider_class
        .install_instructions(db_project)
    end

    def self.check_status_url(db_project)
      "#{API_URL}/package/#{db_project.name}"
    end

    def self.mapping(raw_project)
      MappingBuilder.build_hash(
        name: raw_project["name"],
        description: raw_project["description"],
        repository_url: raw_project["repository_url"],
        homepage: raw_project["homepage"],
        licenses: raw_project["licenses"],
        versions: raw_project["versions"]
      )
    end

    def self.versions(raw_project, _name)
      raw_project["versions"].map do |version|
        VersionBuilder.build_hash(
          number: version["number"],
          original_license: version["original_license"],
          published_at: version["published_at"]
        )
      end
    end

    def self.dependencies(name, version, _mapped_project)
      version_data = get_json("#{API_URL}/package/#{name}")["versions"]
      deps = version_data
        .find { |item| item["number"] == version }
        &.dig("dependencies")&.map(&:split)

      map_dependencies(deps, "runtime")
        .each { |d| d[:requirements] = "*" if d[:requirements].blank? } # consider nil/blank requirements from the API as wildcard "*", since Bibliothecary does
    end
  end
end
