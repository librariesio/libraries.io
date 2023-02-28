# frozen_string_literal: true

class PackageManager::Maven::SpringLibs < PackageManager::Maven::Common
  REPOSITORY_SOURCE_NAME = "SpringLibs"
  HIDDEN = true

  def self.repository_base
    "https://repo.spring.io/libs-release-local"
  end

  def self.project_names
    []
  end

  def self.recent_names
    []
  end
end
