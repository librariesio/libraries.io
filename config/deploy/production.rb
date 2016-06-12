server ENV['WEB_SERVER'], user: ENV['WEB_USER'], roles: %w{app web}

namespace :deploy do
  task :restart do
    on roles(:all) do |host|
      execute "(kill -s SIGUSR1 $(pgrep -f 'puma 3')) || restart librariesio"
    end
  end
  after :publishing, :restart
end
