module PackageManager
  class Pypi
    class JsonApiProjectReleases
      include Enumerable

      def initialize(project_releases)
        @project_releases = project_releases
      end

      def count
        @project_releases.count
      end

      def empty?
        @project_releases.empty?
      end

      def all_releases_have_published_at?
        @project_releases.all?(&:published_at?)
      end

      def each(&block)
        @project_releases.each(&block)
      end
    end
  end
end
