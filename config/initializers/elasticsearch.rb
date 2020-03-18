# frozen_string_literal: true

require "typhoeus/adapters/faraday"
require "google/cloud/trace/faraday_middleware" if Rails.env.production?

url = ENV["ELASTICSEARCH_CLUSTER_URL"] || "localhost:9200"

Elasticsearch::Model.client = Elasticsearch::Client.new hosts: url.split(","),
                                                        retry_on_failure: true,
                                                        randomize_hosts: true,
                                                        transport_options: { request: { timeout: 10 } } do |builder|
  builder.use :http_cache, store: Rails.cache, logger: Rails.logger, shared_cache: false, serializer: Marshal
  builder.use FaradayMiddleware::Gzip
  builder.use Google::Cloud::Trace::FaradayMiddleware if Rails.env.production?
  builder.use :instrumentation
  builder.request :retry
  builder.adapter :typhoeus
end
