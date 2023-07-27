# frozen_string_literal: true

module PackageManager
  class Base
    class ApiVersionToUpsert
      attr_reader :version_number

      def initialize(
        version_number:,
        published_at:,
        runtime_dependencies_count:,
        original_license:,
        repository_sources:,
        status:
      )
        @version_number = version_number
        @published_at = published_at
        @runtime_dependencies_count = runtime_dependencies_count
        @original_license = original_license
        @repository_sources = repository_sources
        @status = status
      end

      def to_version_model_attributes
        {
          number: @version_number,
          published_at: @published_at,
          runtime_dependencies_count: @runtime_dependencies_count,
          original_license: @original_license,
          repository_sources: @repository_sources,
          status: @status,
        }.compact
      end
    end
  end
end
