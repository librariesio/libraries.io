# config valid only for current version of Capistrano
lock '3.11.0'

set :application, 'librariesio'
set :repo_url, 'git@github.com:librariesio/libraries.io.git'
set :branch, 'master'

set :linked_files, fetch(:linked_files, []).push('.env', 'config/secrets.yml')
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/uploads')

set :keep_assets, 2
set :keep_releases, 4
set :bundle_jobs, 6

set :app_server_port, 5000

set :maintenance_template_path, File.join(File.expand_path('../../public/system', __FILE__), 'maintenance.html')

set :migration_role, :cron
set :conditionally_migrate, true

set :bugsnag_api_key, ENV['BUGSNAG_API_KEY']

set :sidekiq_roles, :worker
set :sidekiq_processes, 3
