# frozen_string_literal: true
if Rails.env.production?
  Google::Cloud::Trace.configure do |config|
    sampler = Google::Cloud::Trace::TimeSampler.default
    # there doesn't seem to be a good way to override the configuration for trace as initialize
    # is private and you can't override the defaults?
    sampler.send(:initialize, path_blacklist: ["/_ah/health", "/healthz", "/healthcheck"].freeze, qps: 0.01)
    config.sampler = sampler
    config.notifications << 'cache_read.active_support'
  end

  Google::Cloud::ErrorReporting.configure do |config|
    config.ignore_classes = [ActiveRecord::RecordNotFound]
  end
end
