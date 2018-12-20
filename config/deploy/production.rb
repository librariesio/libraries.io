require "fog/google"
require "json"
google_creds = JSON.load(File.open('.google_creds.json'))
goog_config = {
  google_project: google_creds['project_id'],
  google_client_email: google_creds['client_email'],
  google_json_key_location: '.google_creds.json'
}
goog = Fog::Compute::Google.new(config=goog_config)

web = goog.servers.all(filter: 'labels.project = libraries AND labels.environment = production AND labels.type = app')

memcached = goog.servers.all(filter: 'labels.project = libraries AND labels.environment = production AND labels.role = memcached')

elastic = goog.servers.all(filter: 'labels.project = libraries AND labels.environment = production AND labels.role = elasticsearch')

set :capenv, ->(env) {
  Dotenv.load('.env.prod').each {|k,v| env.add k,v}
  # we're using cloud memorystore for redis and fog doesn't support querying it so hard-code it
  env.add 'REDISCLOUD_URL', "redis://10.0.1.4:6379/0"
  env.add 'MEMCACHIER_SERVERS', memcached.map {|mem| mem.network_interfaces[0][:network_ip] + ':11211'}.join(',')
  env.add 'ELASTICSEARCH_CLUSTER_URL', elastic.map {|es| es.network_interfaces[0][:network_ip] + ':9200'}.join(',')
}

web.each do |s|
  server s.network_interfaces[0][:access_configs][0][:nat_ip], user: 'deploy', roles: [s.labels.fetch(:type, ''), s.labels.fetch(:role, '')]
end
