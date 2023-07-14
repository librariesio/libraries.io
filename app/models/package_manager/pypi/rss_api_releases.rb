module PackageManager
  class Pypi
    class RssApiReleases
      InvalidReleasesFeedStructure = Class.new(ArgumentError)

      def self.request(project_name:)
        data = ApiService.request_and_parse_xml("https://pypi.org/rss/project/#{project_name}/releases.xml")
        raise InvalidReleasesFeedStructure unless data.locate("rss/channel").first

        new(project_name: project_name, data: data)
      end

      def initialize(project_name:, data:)
        @project_name = project_name
        @data = data
      end

      def self.parse_release_data_from_rss_item(item)
        {
          # Don't wrap any errors that might occur here in another error
          # to make it clearer which part of parsing is failing
          number: item.locate("title").first.text,
          published_at: Time.parse(item.locate("pubDate").first.text),
        }
      end

      def releases
        @data.locate("rss/channel/item").map do |item|
          parsed_release_data = self.class.parse_release_data_from_rss_item(item)

          RssApiRelease.new(
            version_number: parsed_release_data[:number],
            published_at: parsed_release_data[:published_at]
          )
        end
      end
    end
  end
end
