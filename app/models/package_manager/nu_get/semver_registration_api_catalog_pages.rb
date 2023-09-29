module PackageManager
  class NuGet
    class SemverRegistrationApiCatalogPages
      def self.request(catalog_page_urls:)
        new(catalog_page_urls.flat_map do |url|
          SemverRegistrationApiCatalogPage.request(url: url).releases
        end)
      end

      attr_reader :releases

      def initialize(releases)
        @releases = releases
      end
    end
  end
end
