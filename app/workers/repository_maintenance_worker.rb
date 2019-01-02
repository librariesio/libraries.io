class BaseRepositoryMaintenanceStatWorker
    def perform(repo_id)
        GatherRepositoryMaintenanceStats.gather_stats(Repository.find_by_id(repo_id))
    end
end


class CriticalRepositoryMaintenanceStatWorker < BaseRepositoryMaintenanceStatWorker
    include Sidekiq::Worker
    sidekiq_options queue: :critical, unique: :until_executed
end