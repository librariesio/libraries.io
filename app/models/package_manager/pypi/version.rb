module PackageManager
  class Pypi
    # An editable container of information about a particular
    # PyPI release. This is transformed into a hash for
    # later consumption by package manager class methods.
    #
    # All of the version-specific requests are done in this class
    # with the data never traveling more than one method away.
    class Version
      attr_reader :number, :published_at, :original_license

      InvalidReleasesFeedStructure = Class.new(ArgumentError)

      # One source of PyPI data is an RSS feed for each package. Most
      # importantly, this provides the publish date for some releases that,
      # for some reason, don't exist in the JSON API.
      def self.retrieve_project_releases_rss_feed(name:)
        data = get_xml("https://pypi.org/rss/project/#{name}/releases.xml")

        # If this stops looking like an RSS feed, it's an error
        raise InvalidReleasesFeedStructure unless data.locate("rss/channel").first

        # No items is not an error
        data.locate("rss/channel/item").map do |item|
          {
            # Don't wrap any errors that might occur here in another error
            # to make it clearer which part of parsing is failing
            number: item.locate("title").first.text,
            published_at: Time.parse(item.locate("pubDate").first.text),
          }
        end
      end

      # Encapsulate remote data gathering for feeds that cover all
      # possible releases. To be used immediately by process_raw_data.
      def self.gather_raw_data_details(
        raw_releases:,
        name:
      )
        raw_release_objs = raw_releases.map { |number, release| RawRelease.new(number: number, release: release) }

        # Don't gather RSS feed details unless we need them
        feed_releases = if !raw_release_objs.all?(&:details?)
                          retrieve_project_releases_rss_feed(name: name)
                        else
                          []
                        end

        { raw_release_objs: raw_release_objs, feed_releases: feed_releases }
      end

      def self.process_raw_data(
        raw_releases:,
        name:,
        known_versions:
      )
        details = gather_raw_data_details(
          raw_releases: raw_releases,
          name: name
        )

        details[:raw_release_objs].map do |raw_release|
          # If we know about this release already, skip the rest of the processing
          next known_versions[raw_release.number] if known_versions.key?(raw_release.number)

          version = raw_release.to_version
          version.retrieve_license_details!(name: name)
          version.maybe_set_feed_published_at!(feed_releases: details[:feed_releases])

          version.to_result
        end
      end

      def initialize(number: nil, published_at: nil)
        @number = number
        @published_at = published_at
      end

      def retrieve_license_details!(name:)
        # The license is stored on the version endpoint
        response = self.class.get("https://pypi.org/pypi/#{name}/#{number}/json")

        # If there's no original license, this is not an error
        @original_license = response.dig("info", "license")
      end

      # Only set the published at date from the feed if it's not
      # already set on the object.
      def maybe_set_feed_published_at!(feed_releases:)
        return if @published_at

        feed_release = feed_releases.find { |fr| fr[:number] == number }
        @published_at = feed_release[:published_at] if feed_release
      end

      def to_result
        {
          number: number,
          published_at: @published_at&.iso8601,
          original_license: original_license,
        }
      end
    end
  end
end
