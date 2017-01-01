class GithubHookWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, unique: :until_executed

  def perform(github_id, sender_id)
    GithubRepository.update_from_hook(github_id, sender_id)
  end
end
