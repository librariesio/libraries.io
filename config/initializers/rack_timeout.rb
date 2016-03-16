Rack::Timeout.timeout = ENV.fetch("TIMEOUT", 10).to_i  # seconds
Rack::Timeout::Logger.disable
