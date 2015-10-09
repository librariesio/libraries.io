class GithubHookWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, unique: true

  def perform(github_id, sender_id)
    github_repository = GithubRepository.find_by_github_id(github_id)
    user = User.find_by_uid(sender_id)
    if user.present? && github_repository.present?
      github_repository.download_manifests(user.token)
      github_repository.update_all_info_async(user.token)
    end
  end
end
