module PackageManager
  class NuGet
    class SemverRegistrationApiProject
      include SemverRegistrationApiHasItems

      def self.request(project_name:)
        data = begin
          ApiService.request_json_with_headers("https://api.nuget.org/v3/registration5-gz-semver2/#{project_name.downcase}/index.json")
        rescue StandardError => e
          Rails.logger.error("Invalid NuGet Semver Registration API Project: #{project_name}: #{e.message}")

          {}
        end

        if data.nil?
          Rails.logger.error("Data is nil for NuGet Semver Registration Project: #{project_name}")

          data = {}
        end

        new(data)
      end

      def initialize(data)
        @data = data
      end

      # NuGet responses contain an items key whose value is an
      # array of objects that contain at least an @id parameter,
      # which contains a URL, and another items array. If that
      # inner items array is empty, you are supposed to retrieve
      # the releases from the URL in the @id key.
      #
      # This is a naive approach to dealing with this. If any
      # inner items array is empty, assume we have to retrieve all
      # of the releases from the individual URLs.
      def any_missing_releases?
        @data["items"].any? { |page| !page["items"] || page["items"].empty? }
      end

      # Return the list of catalog page URLs that can be
      # directly queried for releases.
      def catalog_page_urls
        @data["items"].map { |item| item["@id"] }
      end

      private

      def raw_releases
        @data["items"].flat_map { |page| page["items"] }.compact
      end
    end
  end
end
