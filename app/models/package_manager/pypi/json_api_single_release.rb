module PackageManager
  class Pypi
    class JsonApiSingleRelease
      def self.request(project_name:, version_number:)
        data = ApiService.request_json_with_headers("https://pypi.org/pypi/#{project_name}/#{version_number}/json")

        new(project_name: project_name, version_number: version_number, data: data)
      end

      def initialize(project_name:, version_number:, data:)
        @project_name = project_name
        @version_number = version_number
        @data = data
      end

      def license
        @data.dig("info", "license")
      end
    end
  end
end
