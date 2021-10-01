# frozen_string_literal: true

class PackageManager::Conda::Main < PackageManager::Conda
  REPOSITORY_SOURCE_NAME = "Main"
  HIDDEN = true

  def self.package_link(db_project, _version = nil)
    "https://anaconda.org/anaconda/#{db_project.name}"
  end

  def self.install_instructions(db_project, _version = nil)
    "conda install -c anaconda #{db_project.name}"
  end
end
