module PackageManager
  class Base
    class VersionDeprecator
      def initialize(
        project:,
        version_numbers_to_deprecate:,
        target_status:,
        deprecation_time:
      )
        @project = project
        @version_numbers_to_deprecate = version_numbers_to_deprecate
        @target_status = target_status
        @deprecation_time = deprecation_time
      end

      def deprecate_versions_of_project!
        @project
          .versions
          .where.not(number: @version_numbers_to_deprecate)
          .where("status != ? or status is null", @target_status)
          .update_all(status: @target_status, updated_at: @deprecation_time)
      end
    end
  end
end
