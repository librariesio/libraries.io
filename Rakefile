# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path("config/application", __dir__)

Rails.application.load_tasks

require "elasticsearch/rails/tasks/import"

desc "Run the linter"
task :lint do
  sh "bundle exec rubocop -P"
end

desc "Run the linter with autofix"
task :fix do
  sh "bundle exec rubocop -A"
end
