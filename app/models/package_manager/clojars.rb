# frozen_string_literal: true

module PackageManager
  class Clojars < Maven
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    URL = "https://clojars.org"
    COLOR = "#db5855"
    NAME_DELIMITER = "/"

    def self.package_link(db_project, version = nil)
      "https://clojars.org/#{db_project.name}" + (version ? "/versions/#{version}" : "")
    end

    def self.repository_base
      "https://repo.clojars.org"
    end

    def self.project_names
      []
    end

    def self.recent_names
      get("https://maven.libraries.io/clojars/recent")
    end

    # Clojars download urls require a version
    def self.download_url(db_project, version = nil)
      group_id, artifact_id = db_project.name.split("/", 2)
      artifact_id = group_id if artifact_id.nil?
      MavenUrl.new(group_id, artifact_id, repository_base).jar(version)
    end

    def self.check_status_url(db_project)
      package_link(db_project)
    end
  end
end
