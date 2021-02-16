# frozen_string_literal: true

require "google/cloud/trace/rails"

puts "Google::Cloud::Trace enabled." if Google::Cloud.configure.use_trace
