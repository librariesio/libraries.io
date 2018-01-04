limit_proc = proc do |req|
  if req.params['api_key'].present?
    key = ApiKey.active.find_by_access_token(req.params['api_key'])
    key ? key.rate_limit : 30
  else
    30 # req/min for anonymous users
  end
end

Rack::Attack.throttle('api', :limit => limit_proc, :period => 1.minute) do |req|
  if req.path.match(/^\/api\/.+/) && !req.path.match(/^\/api\/bower-search/)
    req.params['api_key'] || req.ip
  end
end

Rack::Attack.throttle('req/ip', :limit => 5, :period => 1.second) do |req|
  if !req.path.match(/^\/api\/.+/)
    req.ip
  end
end
