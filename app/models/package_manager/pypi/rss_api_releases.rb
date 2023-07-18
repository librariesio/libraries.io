module PackageManager
  class Pypi
    class RssApiReleases
      InvalidReleasesFeedStructure = Class.new(ArgumentError)

      def self.request_url(project_name:)
        "https://pypi.org/rss/project/#{project_name}/releases.xml"
      end

      def self.request(project_name:)
        xml_data = ApiService.request_and_parse_xml(request_url(project_name: project_name))
        raise InvalidReleasesFeedStructure unless xml_data.locate("rss/channel").first

        new(xml_data: xml_data)
      end

      # @param xml_data [Ox::Document] The parsed XML from the RSS request
      def initialize(xml_data:)
        # @type [Ox::Document]
        @xml_data = xml_data
      end

      # @return [Array<PackageManager::Pypi::RssApiRelease>]
      def releases
        @xml_data.locate("rss/channel/item").map do |item|
          parsed_release_data = parse_release_data_from_rss_item(item)

          RssApiRelease.new(
            version_number: parsed_release_data[:version_number],
            published_at: parsed_release_data[:published_at]
          )
        end
      end

      private

      def parse_release_data_from_rss_item(item)
        {
          version_number: item.locate("title").first.text,
          published_at: Time.parse(item.locate("pubDate").first.text),
        }
      rescue StandardError => e
        raise InvalidReleasesFeedStructure, e.inspect
      end
    end
  end
end
