require 'faraday'
require 'typhoeus'
require 'typhoeus/adapters/faraday'

if ENV['ELASTICSEARCH_URL'].present?
  Searchkick.client = Elasticsearch::Client.new url: ENV['ELASTICSEARCH_URL']
end
