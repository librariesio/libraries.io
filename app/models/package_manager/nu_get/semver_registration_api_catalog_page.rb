module PackageManager
  class NuGet
    class SemverRegistrationApiCatalogPage
      include SemverRegistrationApiHasItems

      def self.request(url:)
        data = begin
          ApiService.request_json_with_headers(url)
        rescue StandardError => e
          Rails.logger.error("Invalid NuGet Semver Registration API Catalog Page: #{url}: #{e.message}")

          {}
        end

        if data.nil?
          Rails.logger.error("Data is nil for NuGet Semver Registration API Catalog Page: #{url}")

          data = {}
        end

        new(data)
      end

      def initialize(data)
        @data = data
      end

      private

      def raw_releases
        @data["items"]
      end
    end
  end
end
