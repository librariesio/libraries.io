Octokit.middleware = Faraday::RackBuilder.new do |builder|
  builder.use :http_cache, store: Rails.cache, logger: Rails.logger, shared_cache: false, serializer: Marshal
  builder.use Octokit::Middleware::FollowRedirects
  builder.use Octokit::Response::RaiseError
  builder.use Octokit::Response::FeedParser
  builder.use FaradayMiddleware::Gzip
  builder.use :instrumentation
  builder.request :retry
  builder.adapter :typhoeus
end
