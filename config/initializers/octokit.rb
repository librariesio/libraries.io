# frozen_string_literal: true
Octokit.middleware = Faraday::RackBuilder.new do |builder|
  builder.use Octokit::Middleware::FollowRedirects
  builder.use Octokit::Response::RaiseError
  builder.use Octokit::Response::FeedParser
  builder.use FaradayMiddleware::Gzip
  builder.use :instrumentation
  builder.request :retry
  builder.adapter :typhoeus
  # ethon doesn't expose any other way to shut up its logging :(
  # https://github.com/typhoeus/ethon/issues/82
  Ethon.logger = Logger.new(nil)
end
