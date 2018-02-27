server '51.15.130.54',    user: 'root', roles: %w{cron}

server '163.172.185.77',  user: 'root', roles: %w{app web}
server '163.172.154.122', user: 'root', roles: %w{app web}
server '163.172.161.163', user: 'root', roles: %w{app web}
server '163.172.139.6',   user: 'root', roles: %w{app web}

server '163.172.139.253', user: 'root', roles: %w{app worker}
server '163.172.138.184', user: 'root', roles: %w{app worker}
server '163.172.155.116', user: 'root', roles: %w{app worker}
server '163.172.165.101', user: 'root', roles: %w{app worker}
server '51.15.141.224', user: 'root', roles: %w{app worker}

namespace :deploy do
  task :restart do
    on roles(:app) do |host|
      execute "sleep #{rand(100)} && restart librariesio"
    end
  end

  task :restart_web do
    on roles(:web) do |host|
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
