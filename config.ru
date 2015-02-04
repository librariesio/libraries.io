require ::File.expand_path('../config/environment',  __FILE__)

use Rack::Deflater
use Rack::CanonicalHost, ENV['CANONICAL_HOST'] if ENV['CANONICAL_HOST']

run Rails.application
