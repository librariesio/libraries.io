# frozen_string_literal: true
limit_proc = proc do |req|
  if req.params['api_key'].present?
    key = ApiKey.active.find_by_access_token(req.params['api_key'])
    # an invalid key should get rate limited to zero so that those
    # requests aren't allowed
    key ? key.rate_limit : 0
  else
    10 # req/min for anonymous users
  end
end

Rack::Attack.throttle('api', limit: limit_proc, period: 1.minute) do |req|
  if req.path.match(/^\/api\/.+/) && !req.path.match(/^\/api\/bower-search/)
    req.params['api_key'] || req.ip
  end
end

# throttle scraping
Rack::Attack.throttle('scrapers', limit: 30, period: 5.minutes) do |req|
  req.remote_ip if req.user_agent && req.user_agent.match(/Scrapy.*/)
end
