# frozen_string_literal: true

module PackageManager
  class Maven < MultipleSourcesBase
    class MavenUrl
      DELIMITER = ":"
      GROUP_ARTIFACT_SPLIT_SIZE = 2

      def self.from_name(name, repo_base, delimiter = DELIMITER)
        group_id, artifact_id = *parse_name(name, delimiter)

        # Clojars names, when missing a group id, are implied to have the same group and artifact ids.
        artifact_id = group_id if artifact_id.nil? && delimiter == PackageManager::Clojars::NAME_DELIMITER

        new(group_id, artifact_id, repo_base)
      end

      def self.legal_name?(name, delimiter = DELIMITER)
        name.present? && name.split(delimiter).size == GROUP_ARTIFACT_SPLIT_SIZE
      end

      def self.parse_name(name, delimiter = DELIMITER)
        name.split(delimiter, GROUP_ARTIFACT_SPLIT_SIZE)
      end

      def initialize(group_id, artifact_id, repo_base)
        @group_id = group_id
        @artifact_id = artifact_id
        @repo_base = repo_base
      end

      def base
        "#{@repo_base}/#{group_path}/#{@artifact_id}"
      end

      def jar(version)
        "#{path_base(version)}.jar"
      end

      def pom(version)
        "#{path_base(version)}.pom"
      end

      # this is very specific to Maven Central
      def search(version = nil)
        if version
          "http://search.maven.org/#artifactdetails%7C#{@group_id}%7C#{@artifact_id}%7C#{version}%7Cjar"
        else
          "http://search.maven.org/#search%7Cgav%7C1%7Cg%3A%22#{@group_id}%22%20AND%20a%3A%22#{@artifact_id}%22"
        end
      end

      def maven_metadata
        "#{@repo_base}/#{group_path}/#{@artifact_id}/maven-metadata.xml"
      end

      private

      def group_path
        @group_id.gsub(".", "/")
      end

      def path_base(version)
        "#{base}/#{version}/#{@artifact_id}-#{version}"
      end
    end
  end
end
