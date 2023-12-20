# frozen_string_literal: true

class ProactiveProjectSyncWorker
  include Sidekiq::Worker
  sidekiq_options queue: :small, lock: :until_executed

  PLATFORMS = %w[NPM Maven].freeze
  DEFAULT_LIMIT = 1000

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
      .where("projects.last_synced_at IS NULL OR projects.last_synced_at < ?", last_synced_at_cutoff)
      .order("projects.last_synced_at ASC NULLS FIRST")
  end

  def last_synced_at_cutoff
    7.days.ago
  end
end
