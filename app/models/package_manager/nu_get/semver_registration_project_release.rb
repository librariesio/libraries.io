module PackageManager
  class NuGet
    class SemverRegistrationProjectRelease
      attr_reader :published_at, :version, :project_url, :tags, :licenses, :dependencies, :deprecation

      def initialize(
        published_at:,
        version:,
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
        @version = version
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
        @published_at <=> other.published_at
      end
    end
  end
end
