class CheckStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: :until_executed

  def perform(project_id, removed = false)
    Project.find_by_id(project_id).try(:check_status, removed)
  end
end
