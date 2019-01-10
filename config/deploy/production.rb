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
  next unless s.status == "RUNNING"
  server s.network_interfaces[0][:access_configs][0][:nat_ip], user: 'deploy', roles: [s.labels.fetch(:type, ''), s.labels.fetch(:role, '')]
end

namespace :deploy do
  task :tag_docker_live do
    revision = `git show-ref origin/master`.split.first
    system "gcloud --quiet container images add-tag gcr.io/#{ENV['GOOGLE_PROJECT']}/libraries.io:#{revision} gcr.io/#{ENV['GOOGLE_PROJECT']}/libraries.io:latest"
  end
  after :published , :tag_docker_live

  task :update_k8s do
    revision = `git show-ref origin/master`.split.first
    system "kubectl set image deployment/libraries-sidekiq-worker-deploy libraries-sidekiq-worker=gcr.io/#{ENV['GOOGLE_PROJECT']}/libraries.io:#{revision}"
    system "kubectl set image deployment/libraries-rails libraries-rails=gcr.io/#{ENV['GOOGLE_PROJECT']}/libraries.io:#{revision}"
  end
  before :publishing, :update_k8s

  task :ensure_container_built do
    checks = 0
    max_checks = 10
    revision = `git show-ref origin/master`.split.first
    while checks <= max_checks && !system("gcloud container images describe gcr.io/#{ENV['GOOGLE_PROJECT']}/libraries.io:#{revision}") do
      checks += 1
      print "Waiting for revision #{revision} to be built on Google Container Registry..."
      sleep(60)
    end
    if checks > max_checks
      raise "Didn't build container successfully"
    end
  end
  after :starting, :ensure_container_built
end
