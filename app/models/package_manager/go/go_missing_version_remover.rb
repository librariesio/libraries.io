# frozen_string_literal: true

module PackageManager
  class Go
    class GoMissingVersionRemover
      # should match the same regex that Golang uses to identify pseudo version numbers
      # https://github.com/golang/mod/blob/master/module/pseudo.go#L47C39-L47C135
      PSEUDO_VERSION_REGEX = /^v[0-9]+\.(0\.0-|\d+\.\d+-([^+]*\.)?0\.)\d{14}-[A-Za-z0-9]+(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$/.freeze

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
        version_numbers = @project.versions.map(&:number)

        # Do not consider pseudo version numbers for removal.
        # Our upstream data sources are not consistent with what pseudo versions are returned.
        # If we have seen a pseudo version for a Go module then it was valid at some point and
        # should still be valid going forward.
        # More information on pseudo versions: https://go.dev/ref/mod#pseudo-versions
        non_pseudo_version_numbers = version_numbers.grep_v(PSEUDO_VERSION_REGEX)

        versions_to_remove = non_pseudo_version_numbers - @version_numbers_to_keep

        @project
          .versions
          .where(number: versions_to_remove)
          .where("status != ? or status is null", @target_status)
          .update_all(status: @target_status, updated_at: @removal_time)
      end
    end
  end
end
