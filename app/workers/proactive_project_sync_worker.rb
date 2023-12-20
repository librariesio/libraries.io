# frozen_string_literal: true

class ProactiveProjectSyncWorker
  include Sidekiq::Worker
  sidekiq_options queue: :small, lock: :until_executed

  PLATFORMS = %w[NPM Maven].freeze
  DEFAULT_LIMIT = 1000
  LAST_SYNCED_AT_CUTOFF = -> { 7.days.ago }

  def perform(limit = DEFAULT_LIMIT)
    projects_query
      .limit(limit)
      .each(&:async_sync)
  end

  def projects_query
    Project
      .distinct
      .visible
      .platform(PLATFORMS)
      .where.associated(:repository_maintenance_stats)
      .where("projects.last_synced_at IS NULL OR projects.last_synced_at < ?", LAST_SYNCED_AT_CUTOFF.call)
      .order("projects.last_synced_at ASC NULLS FIRST")
  end
end
