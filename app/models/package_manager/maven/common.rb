# frozen_string_literal: true

class PackageManager::Maven::Common < PackageManager::Maven
  def self.package_link(db_project, version = nil)
    download_url(db_project, version)
  end

  def self.download_url(db_project, version = nil)
    if version
      MavenUrl.from_name(db_project.name, repository_base).jar(version)
    else
      MavenUrl.from_name(db_project.name, repository_base).base
    end
  end

  def self.check_status_url(db_project)
    MavenUrl.from_name(db_project.name, repository_base).base
  end
end
