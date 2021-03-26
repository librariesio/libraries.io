# frozen_string_literal: true

class PackageManager::Conda::Main < PackageManager::Conda
  REPOSITORY_SOURCE_NAME = "Conda"
  HIDDEN = true

  def self.recent_names
    last_update = Version.where(project: Project.where(platform: "Conda")).select(:updated_at).order(updated_at: :desc).limit(1).first&.updated_at
    packages = get_json("#{API_URL}/packages")

    return packages.keys if last_update.nil?

    packages.keys.filter do |name|
      packages[name]["versions"].any? { |version| version["published_at"].is_a?(String) && Time.parse(version["published_at"]) > last_update }
    end
  end

  def self.package_link(project, _version = nil)
    "https://anaconda.org/anaconda/#{project.name}"
  end

  def self.install_instructions(project, _version = nil)
    "conda install -c anaconda #{project.name}"
  end

  def self.project(name)
    get_json("#{API_URL}/main/#{name}")
  end
end
