# frozen_string_literal: true

class PackageManager::Packagist::Main < PackageManager::Packagist
  REPOSITORY_SOURCE_NAME = "Main"
  HIDDEN = true

  def self.package_link(project, version = nil)
    "https://packagist.org/packages/#{project.name}##{version}"
  end
end
