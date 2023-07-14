module PackageManager
  class Pypi
    class VersionProcessor
      def initialize(project_releases:, project_name:, known_versions:)
        @project_releases = project_releases
        @project_name = project_name
        @known_versions = known_versions
      end

      def execute
        @project_releases.map do |project_release|
          next @known_versions[project_release.version_number] if @known_versions.key?(project_release.version_number)

          original_license = JsonApiSingleRelease.request(project_name: @project_name, version_number: project_release.version_number).license
          rss_api_release = rss_api_releases_hash[project_release.version_number]
          published_at = project_release.published_at || rss_api_release&.published_at

          {
            number: project_release.version_number,
            published_at: published_at,
            original_license: original_license,
          }
        end
      end

      def should_retrieve_rss_feed?
        !@project_releases.all?(&:published_at?)
      end

      def rss_api_releases_hash
        return @rss_api_releases_hash if @rss_api_releases_hash

        @rss_api_releases_hash = if should_retrieve_rss_feed?
                                   RssApiReleases.request(project_name: @project_name).releases.each_with_object({}) do |release, obj|
                                     obj[release.version_number] = release
                                   end
                                 else
                                   {}
                                 end
      end
    end
  end
end
