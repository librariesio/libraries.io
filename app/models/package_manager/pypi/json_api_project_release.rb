module PackageManager
  class Pypi
    class JsonApiProjectRelease
      attr_reader :number, :published_at

      def initialize(project:, number:, published_at:)
        @project = project
        @number = number
        @published_at = published_at
      end

      def published_at?
        !!@published_at
      end
    end
  end
end
