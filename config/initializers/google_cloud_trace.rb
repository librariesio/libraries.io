# frozen_string_literal: true

require "google/cloud/trace"

puts "Google::Cloud::Trace enabled." if Google::Cloud.configure.use_trace
