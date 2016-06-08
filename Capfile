# Load DSL and set up stages
require "capistrano/setup"

# Include default deployment tasks
require "capistrano/deploy"

# rails specific capistrano tasks
require 'capistrano/rails'

# puma specific capistrano tasks
require 'capistrano/puma'
require 'capistrano/puma/workers'

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }
