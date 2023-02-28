# frozen_string_literal: true

class PackageManager::Maven::Atlassian < PackageManager::Maven::Common
  REPOSITORY_SOURCE_NAME = "Atlassian"

  def self.repository_base
    "https://packages.atlassian.com/maven-central-local"
  end

  def self.project_names
    []
  end

  def self.recent_names
    get("https://maven.libraries.io/atlassian/recent")
  end
end
