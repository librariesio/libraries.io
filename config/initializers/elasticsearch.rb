if ENV['ELASTICSEARCH_URL'].present?
  Elasticsearch::Model.client = Elasticsearch::Client.new url: ENV['ELASTICSEARCH_URL']
end
