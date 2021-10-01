# frozen_string_literal: true

class PackageManager::Packagist::Main < PackageManager::Packagist
  REPOSITORY_SOURCE_NAME = "Main"
  HIDDEN = true

  def self.package_link(db_project, version = nil)
    "https://packagist.org/packages/#{db_project.name}##{version}"
  end
end
