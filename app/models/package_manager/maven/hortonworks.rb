# frozen_string_literal: true

class PackageManager::Maven::Hortonworks < PackageManager::Maven::Common
  REPOSITORY_SOURCE_NAME = "Hortonworks"

  def self.repository_base
    "https://repo.hortonworks.com/content/groups/releases"
  end

  def self.project_names
    []
  end

  def self.recent_names
    get("https://maven.libraries.io/hortonworks/recent")
  end
end
