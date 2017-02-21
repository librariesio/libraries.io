module GithubRepository
  extend ActiveSupport::Concern

  included do
    IGNORABLE_GITHUB_EXCEPTIONS = [Octokit::Unauthorized, Octokit::InvalidRepository, Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Conflict, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway, Octokit::ClientError]

    def self.create_from_github(full_name, token = nil)
      github_client = AuthToken.new_client(token)
      repo_hash = github_client.repo(full_name, accept: 'application/vnd.github.drax-preview+json').to_hash
      return false if repo_hash.nil? || repo_hash.empty?
      create_from_hash(repo_hash)
    rescue *IGNORABLE_GITHUB_EXCEPTIONS
      nil
    end
  end

  def github_client(token = nil)
    AuthToken.fallback_client(token)
  end

  def download_forks_async(token = nil)
    GithubDownloadForkWorker.perform_async(self.id, token)
  end

  def github_contributions_count
    contributions_count # legacy alias
  end

  def github_id
    uuid # legacy alias
  end
end
