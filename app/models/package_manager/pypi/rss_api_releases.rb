module PackageManager
  class Pypi
    class RssApiReleases
      InvalidReleasesFeedStructure = Class.new(ArgumentError)

      def self.request(name:)
        data = ApiService.get_xml("https://pypi.org/rss/project/#{name}/releases.xml")
        raise InvalidReleasesFeedStructure unless data.locate("rss/channel").first

        new(name: name, data: data)
      end

      def initialize(name:, data:)
        @name = name
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
            request: self,
            number: parsed_release_data[:number],
            published_at: parsed_release_data[:published_at]
          )
        end
      end
    end
  end
end
