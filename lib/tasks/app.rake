namespace :app do
  desc 'restart web dynos'
  task restart: :environment do
    require 'platform-api'
    heroku = PlatformAPI.connect_oauth(ENV['PLATFORM_API_TOKEN'])
    dynos = heroku.dyno.list(ENV['APP_NAME']).select{|d| d['name'].match(/^web/) }
    dynos.each { |d| heroku.dyno.restart(ENV['APP_NAME'], d['name']); sleep 30 }
  end
end
