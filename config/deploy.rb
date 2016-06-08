# config valid only for current version of Capistrano
lock '3.5.0'

set :application, 'librariesio'
set :repo_url, 'git@github.com:librariesio/libraries.io.git'

set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/uploads')

set :keep_assets, 2
