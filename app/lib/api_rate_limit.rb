class ApiRateLimit < Rack::Throttle::Minute
  def whitelisted?(request)
    # only rate limit the api for now
    !request.path.match(/^\/api/i)
  end

  def blacklisted?(request)
    request.params['api_key'].in? ['BLACKLISTED_API_KEY']
  end

  def client_identifier(request)
    request.params['api_key'].presence || request.ip.to_s
  end
end
