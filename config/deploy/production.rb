server ENV['WEB_SERVER'], user: ENV['WEB_USER'], roles: %w{app web}
server ENV['SIDEKIQ_SERVER'], user: ENV['SIDEKIQ_USER'], roles: %w{app}

namespace :deploy do
  task :restart do
    on roles(:app) do |host|
      execute "restart librariesio"
    end
  end
  after :publishing, :restart
end
