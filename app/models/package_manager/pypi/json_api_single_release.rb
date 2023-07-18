module PackageManager
  class Pypi
    class JsonApiSingleRelease
      def self.request(project_name:, version_number:)
        data = ApiService.request_json_with_headers("https://pypi.org/pypi/#{project_name}/#{version_number}/json")

        new(data: data)
      end

      def initialize(data:)
        @data = data
      end

      def license
        @data.dig("info", "license")
      end
    end
  end
end
