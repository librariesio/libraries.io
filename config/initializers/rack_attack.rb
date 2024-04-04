# frozen_string_literal: true

class Rack::Attack
  class Request < ::Rack::Request
    def valid_key
      return @valid_key if defined? @valid_key

      @valid_key = ApiKey.active.find_by_access_token(params["api_key"])
    end

    # Rack::Request doesn't have a trusted_proxies list like ActionDispatch does, so
    # instead of trying to modify Rack::Request's ip_filter, let's just use the same ActionDispatch algorithm.
    # (see https://github.com/rack/rack-attack/issues/145)
    def remote_ip
      req = ActionDispatch::Request.new(env)
      @remote_ip ||= req.remote_ip
    end
  end

  blocklist("invalid api key") do |req|
    begin
      api_key = req.params["api_key"]
    rescue EOFError # req.params can blow up with bad data
      req.GET["api_key"]
    end
    !req.valid_key if api_key.present?
  end

  limit_proc = proc do |req|
    if req.params["api_key"].present?
      req.valid_key.rate_limit
    else
      10 # req/min for anonymous users
    end
  end

  throttle("api", limit: limit_proc, period: 1.minute) do |req|
    req.params["api_key"] || req.remote_ip if req.path.match(/^\/api\/.+/) && !req.path.match(/^\/api\/bower-search/)
  end

  # throttle scraping
  throttle("scrapers", limit: 30, period: 5.minutes) do |req|
    req.remote_ip if req.user_agent&.match(/Scrapy.*/)
  end

  # Adds RateLimit-X headers to throttled responses
  self.throttled_responder = lambda do |request|
    throttle_data = request.env["rack.attack.match_data"]

    # Include the equivalent "X-RateLimit-Reset" and "Retry-After" as seconds left before reset,
    # for clients that might look for either one. Docs:
    #
    #   * "A response that includes the RateLimit-Limit header field MUST also include the RateLimit-Reset."
    #     (from the IETF draft https://www.ietf.org/archive/id/draft-ietf-httpapi-ratelimit-headers-07.html#section-4)
    #
    #   * "Retry-After" is a multi-purpose header that means the same thing
    #     (fropm RFC9110 https://www.rfc-editor.org/rfc/rfc9110#field.retry-after)
    now = throttle_data[:epoch_time]
    retry_after = (throttle_data[:period] - (now % throttle_data[:period])).to_s

    headers = {
      "X-RateLimit-Limit" => throttle_data[:limit].to_s,
      "X-RateLimit-Remaining" => "0",
      "X-RateLimit-Reset" => retry_after,
      "Retry-After" => retry_after,
    }

    [429, headers, ["Retry later\n"]]
  end
end

require "subscribers/rack_attack"
