module PackageManager
  class Base
    class IncomingVersion
      attr_reader :number

      def initialize(
        number:,
        published_at:,
        runtime_dependencies_count:,
        original_license:,
        repository_sources:,
        status:
      )
        @number = number
        @published_at = published_at
        @runtime_dependencies_count = runtime_dependencies_count
        @original_license = original_license
        @repository_sources = repository_sources
        @status = status
      end

      def to_h
        {
          number: @number,
          published_at: @published_at,
          runtime_dependencies_count: @runtime_dependencies_count,
          original_license: @original_license,
          repository_sources: @repository_sources,
          status: @status,
        }.reject { |_k, v| v.nil? }
      end
    end
  end
end
