# frozen_string_literal: true

class RepositoryMaintenanceStatWorker
  include Sidekiq::Worker
  sidekiq_options queue: :repo_maintenance_stat, retry: 3, lock: :until_executed, lock_ttl: 1.hours.to_i, lock_prefix: "maintstatjobs"

  def perform(repo_id)
    Repository.find(repo_id).gather_maintenance_stats
  end

  def self.enqueue(repo_id, priority: :medium)
    queue_name = "repo_maintenance_stat"
    case priority
    when :low
      queue_name = "repo_maintenance_stat_low"
    when :medium
      queue_name = "repo_maintenance_stat"
    when :high
      queue_name = "repo_maintenance_stat_high"
    else
      raise ArgumentError, "Unknown priority! Please set to :low :medium or :high"
    end

    # override the queue name setting for the worker and queue up the work
    set(queue: queue_name).perform_async(repo_id)
  end
end
