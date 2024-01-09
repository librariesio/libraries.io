# frozen_string_literal: true

class PackageManager::Maven::MavenCentral < PackageManager::Maven::Common
  REPOSITORY_SOURCE_NAME = "Maven"
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

  def self.missing_version_remover
    PackageManager::Base::MissingVersionRemover
  end

  # maven-metadata.xml for Maven Central does not appear to be guaranteed to contain all relevant versions for a package
  # So instead, if needed, we will retrieve the versions from the raw HTML index page
  def self.versions(raw_project, name)
    if raw_project && raw_project[:versions]
      raw_project[:versions]
    else
      retrieve_versions(versions_from_html(name), name)
    end
  end

  def self.versions_from_html(name)
    get_html(MavenUrl.from_name(name, repository_base, NAME_DELIMITER).base).css("a").filter_map do |a|
      a.text.chomp("/") if a.text.ends_with?("/") && a.text != "../"
    end
  end
end
