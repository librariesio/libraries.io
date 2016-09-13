class SyncPermissionsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :user, unique: :until_executed

  def perform(user_id)
    user = User.find_by_id(user_id)
    user.update_repo_permissions if user
  end
end
