# frozen_string_literal: true

module PackageManager
  class NuGet
    class SemverRegistrationApiProjectReleasesBuilder
      def self.build(project_name:)
        project = SemverRegistrationApiProject.request(project_name: project_name)

        if project.any_missing_releases?
          new(SemverRegistrationApiCatalogPages.request(catalog_page_urls: project.catalog_page_urls).releases)
        else
          new(project.releases)
        end
      end

      attr_reader :releases

      def initialize(releases)
        @releases = releases
      end
    end
  end
end
