module PackageManager
  class Pypi
    class VersionProcessor
      def initialize(project_releases:, name:, known_versions:)
        @project_releases = project_releases
        @name = name
        @known_versions = known_versions
      end

      def execute
        @project_releases.map do |project_release|
          next @known_versions[project_release.number] if @known_versions.key?(project_release.number)

          original_license = JsonApiSingleRelease.request(name: @name, number: project_release.number).license
          rss_api_release = rss_api_releases.find { |r| r.number == project_release.number }
          published_at = project_release.published_at || rss_api_release&.published_at

          {
            number: project_release.number,
            published_at: published_at,
            original_license: original_license,
          }
        end
      end

      def should_retrieve_rss_feed?
        !@project_releases.all?(&:published_at?)
      end

      def rss_api_releases
        return @rss_api_releases if @rss_api_releases

        @rss_api_releases = if should_retrieve_rss_feed?
                              RssApiReleases.request(name: @name).releases
                            else
                              []
                            end
      end
    end
  end
end
