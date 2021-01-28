# frozen_string_literal: true

class PackageManager::Maven::MavenCentral < PackageManager::Maven
  REPOSITORY_SOURCE_NAME = "Maven"
  SUPPORTS_SINGLE_VERSION_UPDATE = true
  HIDDEN = true

  def self.repository_base
    "https://repo1.maven.org/maven2"
  end

  def self.recent_names
    get("https://maven.libraries.io/mavenCentral/recent")
  end

  def self.one_version(name, version_string)
    retrieve_versions([version_string], name)&.first
  end

  def self.versions(_project, name)
    xml_metadata = get_raw(MavenUrl.from_name(name, repository_base).maven_metadata)
    xml_versions = Nokogiri::XML(xml_metadata).css("version").map(&:text)
    retrieve_versions(xml_versions.filter { |item| !item.ends_with?("-SNAPSHOT") }, name)
  end

  def self.package_link(project, version = nil)
    MavenUrl.from_name(project.name, repository_base).search(version)
  end

  def self.download_url(name, version = nil)
    if version
      MavenUrl.from_name(name, repository_base).jar(version)
    else
      MavenUrl.from_name(name, repository_base).base
    end
  end

  def self.check_status_url(project)
    MavenUrl.from_name(project.name, repository_base).base
  end
end
