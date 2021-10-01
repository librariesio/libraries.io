# frozen_string_literal: true

class PackageManager::Conda::Forge < PackageManager::Conda
  REPOSITORY_SOURCE_NAME = "CondaForge"
  HIDDEN = true

  def self.package_link(db_project, _version = nil)
    "https://anaconda.org/conda-forge/#{db_project.name}"
  end

  def self.install_instructions(db_project, _version = nil)
    "conda install -c conda-forge #{db_project.name}"
  end
end
