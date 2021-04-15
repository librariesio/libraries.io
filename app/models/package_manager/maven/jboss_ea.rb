# frozen_string_literal: true

class PackageManager::Maven::JbossEa < PackageManager::Maven
  REPOSITORY_SOURCE_NAME = "JbossEa"
  HIDDEN = true

  def self.repository_base
    "https://repository.jboss.org/nexus/content/repositories/ea/"
  end

  def self.project_names
    get("https://maven.libraries.io/jBossEa/all")
  end

  def self.recent_names
    get("https://maven.libraries.io/jBossEa/recent")
  end
end
