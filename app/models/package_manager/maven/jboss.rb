# frozen_string_literal: true

class PackageManager::Maven::Jboss < PackageManager::Maven
  REPOSITORY_SOURCE_NAME = "Jboss"
  HIDDEN = true

  def self.repository_base
    "https://repository.jboss.org/nexus/content/repositories/releases/"
  end

  def self.project_names
    get("https://maven.libraries.io/jBoss/all")
  end

  def self.recent_names
    get("https://maven.libraries.io/jBoss/recent")
  end
end
