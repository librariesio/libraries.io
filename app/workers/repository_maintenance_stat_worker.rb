class RepositoryMaintenanceStatWorker
    include Sidekiq::Worker
    sidekiq_options queue: :repo_maintenance_stat, unique: true, lock: :until_executed, unique_across_queues: true, retry: 3

    def perform(repo_id)
        GatherRepositoryMaintenanceStats.gather_stats(Repository.find_by_id(repo_id))
    end

    def self.queue(repo_id, priority: :medium)
        queue_name = "repo_maintenance_stat"
        case priority
        when :low
            queue_name = "repo_maintenance_stat_low"
        when :medium
            queue_name = "repo_maintenance_stat"
        when :high
            queue_name = "repo_maintenance_stat_high"
        else
            raise ArgumentError.new("Unknown priority! Please set to :low :medium or :high")
        end

        self.set(queue: queue_name).perform_async(repo_id)
    end
end
