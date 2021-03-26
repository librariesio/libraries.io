# frozen_string_literal: true

class PackageManager::Conda::Forge < PackageManager::Conda
  REPOSITORY_SOURCE_NAME = "CondaForge"
  HIDDEN = true

  def self.package_link(project, _version = nil)
    "https://anaconda.org/conda-forge/#{project.name}"
  end

  def self.install_instructions(project, _version = nil)
    "conda install -c conda-forge #{project.name}"
  end

  def self.project(name)
    get_json("#{API_URL}/conda-forge/#{name}")
  end
end
