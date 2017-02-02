server ENV['WEB_SERVER_1'],     user: ENV['WEB_USER'],     roles: %w{app web}
server ENV['WEB_SERVER_2'],     user: ENV['WEB_USER'],     roles: %w{app web}
server ENV['WEB_SERVER_3'],     user: ENV['WEB_USER'],     roles: %w{app web}
server ENV['WEB_SERVER_4'],     user: ENV['WEB_USER'],     roles: %w{app web}
server ENV['SIDEKIQ_SERVER_1'], user: ENV['SIDEKIQ_USER'], roles: %w{app worker}
server ENV['SIDEKIQ_SERVER_2'], user: ENV['SIDEKIQ_USER'], roles: %w{app worker}
server ENV['SIDEKIQ_SERVER_3'], user: ENV['SIDEKIQ_USER'], roles: %w{app worker}
server ENV['SIDEKIQ_SERVER_4'], user: ENV['SIDEKIQ_USER'], roles: %w{app worker}
server ENV['SIDEKIQ_SERVER_5'], user: ENV['SIDEKIQ_USER'], roles: %w{app worker}
server ENV['SIDEKIQ_SERVER_6'], user: ENV['SIDEKIQ_USER'], roles: %w{app worker}

namespace :deploy do
  task :restart do
    on roles(:app) do |host|
      execute "sleep #{rand(100)} && restart librariesio"
    end
  end
  task :stop do
    on roles(:worker) do |host|
      execute "stop librariesio"
    end
  end
  task :start do
    on roles(:worker) do |host|
      execute "start librariesio"
    end
  end
  after :publishing, :restart
end
