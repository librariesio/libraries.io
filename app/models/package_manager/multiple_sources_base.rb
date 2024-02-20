# frozen_string_literal: true

module PackageManager
  class MultipleSourcesBase < Base
    HAS_MULTIPLE_REPO_SOURCES = true
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false

    def self.providers(db_project)
      self::PROVIDER_MAP.providers_for(project: db_project).map(&:provider_class)
    end

    def self.package_link(db_project, version = nil)
      self::PROVIDER_MAP
        .best_repository_source(project: db_project, version: version)
        .provider_class
        .package_link(db_project, version)
    end

    def self.download_url(db_project, version = nil)
      self::PROVIDER_MAP
        .best_repository_source(project: db_project, version: version)
        .provider_class
        .download_url(db_project, version)
    end

    def self.check_status_url(db_project)
      self::PROVIDER_MAP
        .best_repository_source(project: db_project)
        .provider_class
        .check_status_url(db_project)
    end

    def self.repository_base
      self::PROVIDER_MAP.default_provider.provider_class.repository_base
    end

    def self.recent_names
      self::PROVIDER_MAP.default_provider.provider_class.recent_names
    end
  end
end
