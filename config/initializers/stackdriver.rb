# Enable tracing if GCLOUD_PROJECT_ID is set
unless ENV["GCLOUD_PROJECT_ID"].nil?
  Google::Cloud::Trace.configure do |config|
    sampler = Google::Cloud::Trace::TimeSampler.default
    # there doesn't seem to be a good way to override the configuration for trace as initialize
    # is private and you can't override the defaults?
    sampler.send(:initialize, path_blacklist: ["/_ah/health", "/healthz", "/healthcheck"].freeze, qps: 0.01)
    config.sampler = sampler
  end
end
