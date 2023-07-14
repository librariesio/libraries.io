module PackageManager
  class Pypi
    class RssApiRelease
      attr_reader :number, :published_at

      def initialize(request:, number:, published_at:)
        @request = request
        @number = number
        @published_at = published_at
      end
    end
  end
end
