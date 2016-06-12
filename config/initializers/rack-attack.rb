limit_proc = proc do |req|
  if req.params['api_key'].present?
    key = ApiKey.active.find_by_access_token(req.params['api_key'])
    key ? key.rate_limit : 30
  else
    30 # req/min for anonymous users
  end
end

Rack::Attack.throttle('api', :limit => limit_proc, :period => 1.minute) do |req|
  (req.params['api_key'] || req.ip) if req.path.match(/^\/api/i)
end
