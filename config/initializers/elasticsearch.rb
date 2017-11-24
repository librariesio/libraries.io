require 'typhoeus/adapters/faraday'

url = ENV['ELASTICSEARCH_CLUSTER_URL'] || 'localhost:9200'

Elasticsearch::Model.client = Elasticsearch::Client.new hosts: url.split(','), retry_on_failure: true do |builder|
  builder.use :http_cache, store: Rails.cache, logger: Rails.logger, shared_cache: false, serializer: Marshal
  builder.use FaradayMiddleware::Gzip
  builder.use :instrumentation
  builder.request :retry
  builder.adapter :typhoeus
end
