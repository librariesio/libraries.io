# frozen_string_literal: true

class PackageManager::Maven::Atlassian < PackageManager::Maven
  REPOSITORY_SOURCE_NAME = "Atlassian"

  def self.repository_base
    "https://packages.atlassian.com/maven-central-local"
  end

  def self.project_names
    get("https://maven.libraries.io/atlassian/all")
  end

  def self.recent_names
    get("https://maven.libraries.io/atlassian/recent")
  end

  def self.package_link(project, version = nil)
    if version
      MavenUrl.from_name(project.name, repository_base).jar(version)
    else
      MavenUrl.from_name(project.name, repository_base).base
    end
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

  def self.db_platform
    "Maven"
  end
end
