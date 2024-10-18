# frozen_string_literal: true

def prod?
  Rails.env.production? && (ENV["DD_AGENT_HOST"].present? || ENV["DD_TRACE_AGENT_URL"].present?)
end

def local_dev?
  Rails.env.development? && ENV["DD_ENABLE_LOCAL"].present?
end

Datadog.configure do |c|
  if prod? || local_dev?
    c.tracing.instrument :rack, quantize: { query: { show: :all } }
    c.tracing.instrument :rails
    c.tracing.instrument :sidekiq, quantize: { args: { show: :all } }
    c.tracing.instrument :faraday
    c.tracing.instrument :elasticsearch
    c.tracing.instrument :active_record, service_name: "libraries_postgres"
    c.tracing.instrument :pg, service_name: "libraries_pg"

    # turn on Ruby profiler; there's also a require in config.ru
    # that is part of this.
    c.profiling.enabled = false
  else
    c.tracing.enabled = false
  end

  c.env = Rails.env
  # use the github SHA as the version
  # same as initializers/git_revision.rb, but can't use that due to initializer load order
  git_revision = if Rails.env.development?
                   `git rev-parse HEAD`
                 else
                   ENV["REVISION_ID"].presence
                 end
  c.version = git_revision&.rstrip

  # Breaks down very large traces into smaller batches (documented as experimental as of 2022-01-12)
  c.tracing.partial_flush.enabled = true

  # Uncomment this line if you want to see traces in the rails console's stdout
  # c.diagnostics.debug = true
end
