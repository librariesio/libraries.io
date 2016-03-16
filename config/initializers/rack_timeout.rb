Rack::Timeout.timeout = ENV.fetch("TIMEOUT", 10)  # seconds
Rack::Timeout::Logger.disable
