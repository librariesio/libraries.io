require 'dotenv'
Dotenv.load
require "capistrano/setup"
require "capistrano/deploy"
require 'capistrano/rails'
require 'capistrano/maintenance'
require "capistrano/scm/git"
require 'bugsnag/capistrano'
install_plugin Capistrano::SCM::Git

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }
