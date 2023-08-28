# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

# use Rack::Deflater
use Rack::CanonicalHost, ENV["CANONICAL_HOST"], ignore: "localhost" if ENV["CANONICAL_HOST"]

Rails.application.load_server
