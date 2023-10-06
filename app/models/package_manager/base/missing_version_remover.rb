# frozen_string_literal: true

module PackageManager
  class Base
    class MissingVersionRemover
      def initialize(
        project:,
        version_numbers_to_keep:,
        target_status:,
        removal_time:
      )
        @project = project
        @version_numbers_to_keep = version_numbers_to_keep
        @target_status = target_status
        @removal_time = removal_time
      end

      def remove_missing_versions_of_project!
        @project
          .versions
          .where.not(number: @version_numbers_to_keep)
          .where("status != ? or status is null", @target_status)
          .update_all(status: @target_status, updated_at: @removal_time)
      end
    end
  end
end
