# frozen_string_literal: true

class PackageManager::Maven::Atlassian < PackageManager::Maven
  REPOSITORY_SOURCE_NAME = "Atlassian"

  def self.repository_base
    "https://packages.atlassian.com/maven-central-local"
  end

  def self.project_names
    get("http://localhost:8080/atlassian/all")
  end

  def self.recent_names
    get("http://localhost:8080/atlassian/recent")
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

  def self.formatted_name
    PackageManager::Maven.formatted_name
  end

  def self.name
    PackageManager::Maven.name
  end
end
