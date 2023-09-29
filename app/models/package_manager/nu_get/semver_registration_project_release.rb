# frozen_string_literal: true

module PackageManager
  class NuGet
    class SemverRegistrationProjectRelease
      attr_reader :published_at, :version_number, :project_url, :tags, :licenses, :dependencies, :deprecation

      def initialize(
        published_at:,
        version_number:,
        project_url:,
        deprecation:,
        description:,
        summary:,
        tags:,
        licenses:,
        license_url:,
        dependencies:
      )
        @published_at = published_at
        @version_number = version_number
        @project_url = project_url
        @deprecation = deprecation
        @description = description
        @summary = summary
        @tags = tags
        @licenses = licenses
        @license_url = license_url
        @dependencies = dependencies
      end

      def description
        @description.blank? ? @summary : @description
      end

      def original_license
        [
          @licenses, @license_url
        ].detect(&:present?)
      end

      def <=>(other)
        # this helps deal with nuget versions that are unlisted, which will all
        # have the same publishing date of 1900-01-01
        # those versions are likely old or beta, so we don't need to worry too
        # much about using them properly.
        return @version_number <=> other.version_number if @published_at == other.published_at

        @published_at <=> other.published_at
      end
    end
  end
end
