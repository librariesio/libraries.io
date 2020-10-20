# frozen_string_literal: true

class PackageManager::Maven::Hortonworks < PackageManager::Maven
  REPOSITORY_SOURCE_NAME = "Hortonworks"

  def self.repository_base
    "https://repo.hortonworks.com/content/groups/releases"
  end

  def self.project_names
    get("https://maven.libraries.io/hortonworks/all")
  end

  def self.recent_names
    get("https://maven.libraries.io/hortonworks/recent")
  end

  def self.package_link(project, version = nil)
    download_url(project.name, version)
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
