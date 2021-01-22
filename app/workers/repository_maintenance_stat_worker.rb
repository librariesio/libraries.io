class RepositoryMaintenanceStatWorker
    include Sidekiq::Worker
    sidekiq_options queue: :low, retry: 3

    def perform(repo_id)
        Repository.find(repo_id).gather_maintenance_stats
    end
end
