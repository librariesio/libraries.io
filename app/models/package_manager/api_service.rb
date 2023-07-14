module PackageManager
  class ApiService
    def self.request(url, options = {})
      connection = Faraday.new url.strip, options do |builder|
        builder.use FaradayMiddleware::Gzip
        builder.use FaradayMiddleware::FollowRedirects, limit: 3
        builder.request :retry, { max: 2, interval: 0.05, interval_randomness: 0.5, backoff_factor: 2 }

        builder.use :instrumentation
        builder.adapter :typhoeus
      end
      connection.get
    end

    def self.get(url, options = {})
      Oj.load(get_raw(url, options))
    end

    def self.get_raw(url, options = {})
      rsp = request(url, options)
      return "" unless rsp.status == 200

      rsp.body
    end

    def self.get_html(url, options = {})
      Nokogiri::HTML(get_raw(url, options))
    end

    def self.get_xml(url, options = {})
      Ox.parse(get_raw(url, options))
    end

    def self.get_json(url)
      get(url, headers: { "Accept" => "application/json" })
    end
  end
end
