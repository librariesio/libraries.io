ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)

abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'spec_helper'
require 'rspec/rails'
require 'webmock/rspec'

Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

# Enforce that tests can't make unmocked http requests
WebMock.disable_net_connect!(allow_localhost: true)
WebMock.enable!

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.ignore_localhost = true
  config.hook_into :webmock
  # when you add a new cassette name, you have to
  # VCR_ENABLE_NEW_RECORDING=1 the first time you run that test.
  config.default_cassette_options = {
    record: ENV["VCR_ENABLE_NEW_RECORDING"] ? :once : :none,
    decode_compressed_response: true
  }
end

require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist
Capybara.default_max_wait_time = 10

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, window_size: [1280, 600])
end

OmniAuth.config.test_mode = true

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.include Capybara::DSL
end

def project_json_response(projects)
  projects.as_json(only: Project::API_FIELDS, methods: [:package_manager_url, :stars, :forks, :keywords, :latest_stable_release, :latest_download_url, :scm_license], include: {versions: {only: [:number, :published_at, :original_license, :spdx_expression, :researched_at]} })
end

RSpec::Sidekiq.configure do |config|
  config.warn_when_jobs_not_processed_by_sidekiq = false
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
