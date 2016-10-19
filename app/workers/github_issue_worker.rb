class GithubIssueWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: :until_executed

  def perform(name_with_owner, issue_number, token = nil)
    token = token || AuthToken.token
    repo = GithubRepository.create_from_github(name_with_owner, token)
    return unless repo
    issue_hash = AuthToken.fallback_client(token).issue(repo.full_name, issue_number)
    GithubIssue.create_from_hash(repo, issue_hash)
  rescue Octokit::NotFound
    nil
  end
end
