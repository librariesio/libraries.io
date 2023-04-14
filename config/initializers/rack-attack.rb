# frozen_string_literal: true

class Rack::Attack
  class Request < ::Rack::Request
    def valid_key
      return @valid_key if defined? @valid_key

      @valid_key = ApiKey.active.find_by_access_token(params["api_key"])
    end
  end

  blocklist("invalid api key") do |req|
    !req.valid_key if req.params["api_key"].present?
  end

  limit_proc = proc do |req|
    if req.params["api_key"].present?
      req.valid_key.rate_limit
    else
      10 # req/min for anonymous users
    end
  end

  throttle('api', limit: limit_proc, period: 1.minute) do |req|
    if req.path.match(/^\/api\/.+/) && !req.path.match(/^\/api\/bower-search/)
      req.params['api_key'] || req.ip
    end
  end

  # throttle scraping
  throttle('scrapers', limit: 30, period: 5.minutes) do |req|
    req.ip if req.user_agent && req.user_agent.match(/Scrapy.*/)
  end
end

require "subscribers/rack-attack"
