# frozen_string_literal: true

require "ddtrace"

Datadog.configure do |c|
  if Rails.env.production? && (ENV["DD_AGENT_HOST"].present? || ENV["DD_TRACE_AGENT_URL"].present?)
    c.tracing.instrument :rack, quantize: { query: { show: :all } }
    c.tracing.instrument :rails
    c.tracing.instrument :sidekiq, tag_args: true
    c.tracing.instrument :faraday
    c.tracing.instrument :elasticsearch
    c.tracing.instrument :postgres, service_name: "libraries_postgres"

    # turn on Ruby profiler; there's also a require in config.ru
    # that is part of this.
    c.profiling.enabled = false
  else
    # Tracer can be disabled with DD_TRACE_ENABLED="false" too
    c.tracing.transport_options = lambda { |t|
      t.adapter :test # no-op transport
    }
    c.diagnostics.startup_logs.enabled = false
  end

  c.env = Rails.env
  # use the github SHA as the version
  # same as initializers/git_revision.rb, but can't use that due to initializer load order
  git_revision = if Rails.env.development?
                   `git rev-parse HEAD`
                 else
                   ENV["GIT_COMMIT"].presence
                 end
  c.version = git_revision&.rstrip

  # Breaks down very large traces into smaller batches (documented as experimental as of 2022-01-12)
  c.tracing.partial_flush.enabled = true

  # Uncomment this line if you want to see traces in the rails console's stdout
  # c.diagnostics.debug = true
end
