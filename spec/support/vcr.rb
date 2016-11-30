require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.ignore_hosts 'codeclimate.com'
  config.ignore_localhost = true
end
