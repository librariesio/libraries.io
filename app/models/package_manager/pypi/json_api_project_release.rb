module PackageManager
  class Pypi
    class JsonApiProjectRelease
      attr_reader :version_number, :published_at, :yanked_reason

      PYPI_PRERELEASE = /(a|b|rc|dev)[-_.]?[0-9]*$/.freeze

      def initialize(
        version_number:,
        published_at:,
        is_yanked:,
        yanked_reason:
      )
        @version_number = version_number
        @published_at = published_at
        @is_yanked = is_yanked
        @yanked_reason = yanked_reason
      end

      def published_at?
        !@published_at.nil?
      end

      def prerelease?
        @version_number =~ PYPI_PRERELEASE
      end

      def yanked?
        @is_yanked
      end
    end
  end
end
