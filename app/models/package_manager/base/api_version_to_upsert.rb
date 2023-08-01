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
        non_nillable_attributes = {
          number: @version_number,
          published_at: @published_at,
          runtime_dependencies_count: @runtime_dependencies_count,
          original_license: @original_license,
          repository_sources: @repository_sources,
        }.compact

        # If the status is currently "Removed" and a change comes in to update that status to nil/"Active",
        # Update the version's status
        non_nillable_attributes.merge({ status: @status })
      end
    end
  end
end
