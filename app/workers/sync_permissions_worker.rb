class SyncPermissionsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, unique: :until_executed

  def perform(user_id)
    User.find_by_id(user_id).try(:update_repo_permissions)
  end
end
