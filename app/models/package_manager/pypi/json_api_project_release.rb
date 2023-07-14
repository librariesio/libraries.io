module PackageManager
  class Pypi
    class JsonApiProjectRelease
      attr_reader :version_number, :published_at

      def initialize(version_number:, published_at:)
        @version_number = version_number
        @published_at = published_at
      end

      def published_at?
        !@published_at.nil?
      end
    end
  end
end
