class CheckStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: :until_executed

  def perform(project_id, platform, project_name, removed = false)
    Project.check_status(project_id, platform, project_name, removed)
  end
end
