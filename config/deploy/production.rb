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

redis = goog.servers.all(filter: 'labels.project = libraries AND labels.environment = production AND labels.role = redis')

elastic = goog.servers.all(filter: 'labels.project = libraries AND labels.environment = production AND labels.role = elasticsearch')

set :capenv, ->(env) {
  Dotenv.load.keys.each {|k| env.add k}
  env.add 'MEMCACHIER_SERVERS', memcached.map {|mem| mem.network_interfaces[0][:network_ip] + ':11211'}.join(',')
  env.add 'REDISCLOUD_URL', "redis://#{redis.first.network_interfaces[0][:network_ip]}:6379/0"
  env.add 'ELASTICSEARCH_CLUSTER_URL', elastic.map {|es| es.network_interfaces[0][:network_ip] + ':9200'}.join(',')
}

web.each do |s|
  server s.network_interfaces[0][:access_configs][0][:nat_ip], user: 'deploy', roles: [s.labels.fetch(:type, ''), s.labels.fetch(:role, '')]
end

# server '51.15.130.54',    user: 'root', roles: %w{cron}

# namespace :deploy do
#   task :restart do
#     on roles(:app) do |host|
#       within '/var/www/librariesio/current/' do
#         execute :sleep, rand(10)
#         execute :bundle, :exec, :pumactl, :restart
#       end
#     end
#   end

#   task :restart_web do
#     on roles(:web) do |host|
#       within '/var/www/librariesio/current/' do
#         execute :sleep, rand(10)
#         execute :bundle, :exec, :pumactl, :restart
#       end
#     end
#   end

#   task :stop do
#     on roles(:worker) do |host|
#       execute "systemctl --user stop librariesio"
#     end
#   end

#   task :start do
#     on roles(:worker) do |host|
#       execute "systemctl --user start librariesio"
#     end
#   end
#   after :publishing, :restart
# end
