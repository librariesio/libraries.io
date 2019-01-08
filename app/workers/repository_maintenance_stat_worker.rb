class RepositoryMaintenanceStatWorker
    include Sidekiq::Worker
    ##
    # These settings will create a lock using a combination of the worker class and arguments passed.
    # This will prevent a second request for the same repository to be added to the Sidekiq queue and
    # will keep the existing request. There are three queues in use which are set with different priority levels.
    # This lock will exist across the different priority queues to prevent
    # duplication at different priorities for the same repository. By default this worker will use the
    # medium priority queue. If a request is rejected because of an existing lock, then a message will be sent to the logs.
    sidekiq_options queue: :repo_maintenance_stat, lock: :until_and_while_executing, unique_across_queues: true, retry: 3, on_conflict: :log

    def perform(repo_id)
        GatherRepositoryMaintenanceStats.gather_stats(Repository.find_by_id(repo_id))
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
            raise ArgumentError.new("Unknown priority! Please set to :low :medium or :high")
        end

        # override the queue name setting for the worker and queue up the work
        self.set(queue: queue_name).perform_async(repo_id)
    end
end
