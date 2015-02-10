Octokit.middleware = Faraday::RackBuilder.new do |builder|
  store = ActiveSupport::Cache.lookup_store(:file_store, [Dir.pwd + '/tmp'])
  logger = Logger.new(STDOUT)
  logger.level = Logger::DEBUG unless ENV['RACK_ENV'] == 'production'
  builder.use :http_cache, store: store, logger: logger, shared_cache: false, serializer: Marshal
  builder.use Octokit::Response::RaiseError
  builder.request :retry
  builder.adapter :typhoeus
end

# Verbose logging in Octokit
Octokit.configure do |config|
  config.middleware.response :logger unless ENV['RACK_ENV'] == 'production'
end
