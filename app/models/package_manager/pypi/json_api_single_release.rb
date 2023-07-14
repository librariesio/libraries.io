module PackageManager
  class Pypi
    class JsonApiSingleRelease
      def self.request(name:, number:)
        data = ApiService.get("https://pypi.org/pypi/#{name}/#{number}/json")

        new(name: name, number: number, data: data)
      end

      def initialize(name:, number:, data:)
        @name = name
        @number = number
        @data = data
      end

      def license
        @data.dig("info", "license")
      end
    end
  end
end
