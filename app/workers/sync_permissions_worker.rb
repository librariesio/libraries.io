class SyncPermissionsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :user, unique: true

  def perform(user_id)
    user = User.find(user_id)
    user.update_repo_permissions
  end
end
