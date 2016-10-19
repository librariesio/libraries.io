# server ENV['WEB_SERVER'], user: ENV['WEB_USER'], roles: %w{app web}
# server '163.172.185.77', user: ENV['WEB_USER'], roles: %w{app web}
# server '163.172.149.206', user: ENV['WEB_USER'], roles: %w{app web}
server ENV['SIDEKIQ_SERVER'], user: ENV['SIDEKIQ_USER'], roles: %w{app worker}
server ENV['SIDEKIQ_SERVER2'], user: ENV['SIDEKIQ_USER'], roles: %w{app worker}
server ENV['SIDEKIQ_SERVER3'], user: ENV['SIDEKIQ_USER'], roles: %w{app worker}

namespace :deploy do
  task :restart do
    on roles(:app) do |host|
      execute "restart librariesio"
    end
    # on roles(:web) do |host|
    #   execute "cd #{current_path} && bundle exec pumactl -P #{fetch(:puma_state)} restart"
    # end
  end
  after :publishing, :restart
end
