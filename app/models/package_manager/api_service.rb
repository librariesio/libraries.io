# frozen_string_literal: true

module PackageManager
  class ApiService
    MAX_RETRIES = 2
    RETRY_INTERVAL = 0.05
    RETRY_INTERVAL_RANDOMNESS = 0.5
    BACKOFF_FACTOR = 2
    FOLLOW_REDIRECT_LIMIT = 3

    # Make a request for a remote resource, retrying as needed.
    def self.make_retriable_request(url, options = {})
      connection = Faraday.new url.strip, options do |builder|
        builder.use FaradayMiddleware::Gzip
        builder.use FaradayMiddleware::FollowRedirects, limit: FOLLOW_REDIRECT_LIMIT
        builder.request :retry, {
          max: MAX_RETRIES,
          interval: RETRY_INTERVAL,
          interval_randomness: RETRY_INTERVAL_RANDOMNESS,
          backoff_factor: BACKOFF_FACTOR,
        }

        builder.use :instrumentation
        builder.adapter :typhoeus
      end
      connection.get
    end

    def self.request_and_parse_json(url, options = {})
      Oj.load(request_raw_data(url, options))
    end

    # Request raw data from a remote resource.
    def self.request_raw_data(url, options = {})
      rsp = make_retriable_request(url, options)
      return "" unless rsp.status == 200

      rsp.body
    end

    def self.request_and_parse_html(url, options = {})
      Nokogiri::HTML(request_raw_data(url, options))
    end

    # @return [Ox::Document] The parsed XML data
    def self.request_and_parse_xml(url, options = {})
      Ox.parse(request_raw_data(url, options))
    end

    # Request and parse JSON data, providing the Accept headers
    # for a JSON request.
    def self.request_json_with_headers(url)
      request_and_parse_json(url, headers: { "Accept" => "application/json" })
    end
  end
end
