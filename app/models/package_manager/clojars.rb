# frozen_string_literal: true

module PackageManager
  class Clojars < Maven
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_SUPPORT = true
    URL = "https://clojars.org"
    COLOR = "#db5855"

    def self.package_link(project, version = nil)
      "https://clojars.org/#{project.name}" + (version ? "/versions/#{version}" : "")
    end

    def self.repository_base
      "https://repo.clojars.org"
    end

    def self.project_names
      get("https://maven.libraries.io/clojars/all")
    end

    def self.recent_names
      get("https://maven.libraries.io/clojars/recent")
    end

    def self.download_url(name, version = nil)
      group_id, artifact_id = name.split("/", 2)
      artifact_id = group_id if artifact_id.nil?
      MavenUrl.new(group_id, artifact_id, repository_base).jar(version)
    end
  end
end
