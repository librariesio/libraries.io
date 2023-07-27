# frozen_string_literal: true

module PackageManager
  class Pypi
    class RssApiRelease
      attr_reader :version_number, :published_at

      def initialize(version_number:, published_at:)
        @version_number = version_number
        @published_at = published_at
      end
    end
  end
end
