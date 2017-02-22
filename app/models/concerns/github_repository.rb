module GithubRepository
  extend ActiveSupport::Concern

  included do
    IGNORABLE_GITHUB_EXCEPTIONS = [Octokit::Unauthorized, Octokit::InvalidRepository, Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Conflict, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway, Octokit::ClientError]
  end

  def github_client(token = nil)
    AuthToken.fallback_client(token)
  end

  def github_contributions_count
    contributions_count # legacy alias
  end

  def github_id
    uuid # legacy alias
  end
end
