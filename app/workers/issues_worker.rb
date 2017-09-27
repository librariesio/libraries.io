class IssuesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :issues, unique: :until_executed

  def perform(repo_id, token = nil)
    Repository.find_by_id(repo_id).try(:download_issues, token)
  end
end
