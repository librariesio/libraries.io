# frozen_string_literal: true

class PackageManager::Conda::Main < PackageManager::Conda
  REPOSITORY_SOURCE_NAME = "Main"
  HIDDEN = true

  def self.package_link(project, _version = nil)
    "https://anaconda.org/anaconda/#{project.name}"
  end

  def self.install_instructions(project, _version = nil)
    "conda install -c anaconda #{project.name}"
  end
end
