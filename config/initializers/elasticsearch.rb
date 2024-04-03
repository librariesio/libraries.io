# frozen_string_literal: true

require "typhoeus/adapters/faraday"

url = ENV["ELASTICSEARCH_CLUSTER_URL"] || "localhost:9200"

Elasticsearch::Model.client = Elasticsearch::Client.new hosts: url.split(","),
                                                        retry_on_failure: true,
                                                        randomize_hosts: true,
                                                        transport_options: { request: { timeout: 10 } } do |builder|
                                                          builder.use FaradayMiddleware::Gzip
                                                          builder.use :instrumentation
                                                          builder.request :retry
                                                          builder.adapter :typhoeus
                                                        end

# TODO: we can drop this once we remove the elasticsearch* gems.
module Elasticsearch::Model::Adapter::ActiveRecord::Importing
  # Monkeypatch: this is a backport patch of https://github.com/elastic/elasticsearch-rails/commit/80f85905c03e4b426794129463c8fa512e2757e1
  # which is not in the elasticsearch-* gems in the 5.* release stream, which libraries is on. We can't upgrade because the newer major versions
  # of the gems require newer versions of ES, but we need this patch for compatibility with Ruby 3. The only change here is the
  # "**options" since the AR method accepts kwargs and not an options Hash.
  #
  # Fetch batches of records from the database (used by the import method)
  #
  #
  # @see http://api.rubyonrails.org/classes/ActiveRecord/Batches.html ActiveRecord::Batches.find_in_batches
  #
  # rubocop: disable Style/RedundantSelf
  # rubocop: disable Lint/UnusedMethodArgument
  def __find_in_batches(options = {}, &block)
    query = options.delete(:query)
    named_scope = options.delete(:scope)
    preprocess = options.delete(:preprocess)

    scope = self
    scope = scope.__send__(named_scope) if named_scope
    scope = scope.instance_exec(&query) if query

    scope.find_in_batches(**options) do |batch|
      yield (preprocess ? self.__send__(preprocess, batch) : batch)
    end
  end
  # rubocop: enable Style/RedundantSelf
  # rubocop: enable Lint/UnusedMethodArgument
end
