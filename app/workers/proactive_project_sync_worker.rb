# frozen_string_literal: true

class ProactiveProjectSyncWorker
  include Sidekiq::Worker
  # TODO: confirm vvv
  sidekiq_options queue: :small, lock: :until_executed

  PLATFORMS = %w[NPM Go].freeze
  DEFAULT_LIMIT = 1000

  def perform(limit = nil)
    projects_query(limit: limit)
      .each(&:async_sync)
  end

  def projects_query(limit: DEFAULT_LIMIT)
    Project
      .visible
      .platforms(PLATFORMS)
      .where.associated(:repository_maintenance_stats)
      .order("last_synced_at ASC NULLS FIRST")
      .limit(limit)
  end
end
