# frozen_string_literal: true

module PackageManager
  class MultipleSourcesBase < Base
    HAS_MULTIPLE_REPO_SOURCES = true
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false

    def self.providers(project)
      project
        .versions
        .flat_map(&:repository_sources)
        .compact
        .uniq
        .map { |source| self::PROVIDER_MAP[source] } || [self::PROVIDER_MAP["default"]]
    end

    def self.package_link(project, version = nil)
      db_version = project.versions.find_by(number: version)
      repository_source = db_version&.repository_sources&.first.presence || "default"
      self::PROVIDER_MAP[repository_source].package_link(project, version)
    end

    def self.download_url(db_project, version = nil)
      db_version = if version.nil?
          db_project.versions.first
        elsif db_project.association(:versions).loaded?
          db_project.versions.find { |v| v.number == version }
        else
          db_project.versions.find_by(number: version)
        end
      repository_source = db_version&.repository_sources&.first.presence || "default"
      self::PROVIDER_MAP[repository_source].download_url(db_project, version)
    end

    def self.check_status_url(project)
      source = project.versions.flat_map(&:repository_sources).compact.uniq.first.presence || "default"
      self::PROVIDER_MAP[source].check_status_url(project)
    end

    def self.repository_base
      self::PROVIDER_MAP["default"].repository_base
    end

    def self.recent_names
      self::PROVIDER_MAP["default"].recent_names
    end
  end
end
