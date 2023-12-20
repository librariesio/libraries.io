# frozen_string_literal: true

class ProactiveProjectSyncWorker
  include Sidekiq::Worker
  # TODO: confirm vvv
  sidekiq_options queue: :small, lock: :until_executed

  PLATFORMS = %w[NPM Maven].freeze
  DEFAULT_LIMIT = 1000

  def perform(limit = nil)
    projects_query(limit: limit)
      .each(&:async_sync)
  end

  def projects_query(limit: DEFAULT_LIMIT)
    Project
      .distinct
      .visible
      .platform(PLATFORMS)
      .where.associated(:repository_maintenance_stats)
      .where("projects.last_synced_at IS NULL OR projects.last_synced_at < ?", last_synced_at_cutoff)
      .order("projects.last_synced_at ASC NULLS FIRST")
      .limit(limit)
  end

  def last_synced_at_cutoff
    7.days.ago
  end
end
