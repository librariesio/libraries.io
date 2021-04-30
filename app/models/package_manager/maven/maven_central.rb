# frozen_string_literal: true

class PackageManager::Maven::MavenCentral < PackageManager::Maven::Common
  REPOSITORY_SOURCE_NAME = "Maven"
  SUPPORTS_SINGLE_VERSION_UPDATE = true
  HIDDEN = true

  def self.repository_base
    "https://repo1.maven.org/maven2"
  end

  def self.recent_names
    get("https://maven.libraries.io/mavenCentral/recent")
  end

  def self.one_version(raw_project, version_string)
    retrieve_versions([version_string], raw_project[:name])&.first
  end
end
