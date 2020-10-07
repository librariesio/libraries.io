# frozen_string_literal: true

class PackageManager::Maven::MavenCentral < PackageManager::Maven
  REPOSITORY_SOURCE_NAME = "Maven"

  def self.package_link(project, version = nil)
    if version
      MavenUrl.from_name(project.name, repository_base).search(version)
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
