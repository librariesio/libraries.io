class GithubDownloadWorker
  include Sidekiq::Worker

  def perform(repo_id, token)
    # load repo from repo_id
    # update_all_info with token
  end
end
