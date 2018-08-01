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

web.each do |s|
  server s.network_interfaces[0][:access_configs][0][:nat_ip], user: 'deploy', roles: [s.labels.fetch(:type, ''), s.labels.fetch(:role, '')]
end

# server '51.15.130.54',    user: 'root', roles: %w{cron}

namespace :deploy do
  task :restart do
    on roles(:app) do |host|
      execute "sleep #{rand(100)} && systemctl --user restart librariesio"
    end
  end

  task :restart_web do
    on roles(:web) do |host|
      execute "sleep #{rand(100)} && systemctl --user restart librariesio"
    end
  end

  task :stop do
    on roles(:worker) do |host|
      execute "systemctl --user stop librariesio"
    end
  end
  task :start do
    on roles(:worker) do |host|
      execute "systemctl --user start librariesio"
    end
  end
  after :publishing, :restart
end
