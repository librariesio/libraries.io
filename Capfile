require 'dotenv'
Dotenv.load
require "capistrano/setup"
require "capistrano/deploy"
require 'capistrano/rails'
require 'capistrano/maintenance'
require "capistrano/scm/git"
require 'capistrano/rails/console'
require 'capistrano/puma'
install_plugin Capistrano::SCM::Git
install_plugin Capistrano::Puma

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }

require 'appsignal/capistrano'
