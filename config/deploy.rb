# config valid only for current version of Capistrano
lock '3.7.1'

set :application, 'librariesio'
set :repo_url, 'git@github.com:librariesio/libraries.io.git'

set :linked_files, fetch(:linked_files, []).push('.env', 'config/secrets.yml')
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/uploads')

set :keep_assets, 2
set :keep_releases, 4
set :bundle_jobs, 6

set :nginx_domains, "libraries.io staging.libraries.io"
set :nginx_read_timeout, 60
set :app_server_port, 5000

set :puma_conf, "#{current_path}/config/puma.rb"
set :puma_state, "#{shared_path}/tmp/pids/puma.state"

set :maintenance_template_path, File.join(File.expand_path('../../public/system', __FILE__), 'maintenance.html')
