module GithubRepository
  extend ActiveSupport::Concern

  included do
    IGNORABLE_GITHUB_EXCEPTIONS = [Octokit::Unauthorized, Octokit::InvalidRepository, Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Conflict, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway, Octokit::ClientError]
  end

  def github_client(token = nil)
    AuthToken.fallback_client(token)
  end

  def get_github_file_list(token = nil)
    tree = AuthToken.fallback_client(token).tree(full_name, default_branch, :recursive => true).tree
    tree.select{|item| item.type == 'blob' }.map{|file| file.path }
  end

  def get_github_file_contents(path, token = nil)
    Base64.decode64 AuthToken.fallback_client(token).contents(full_name, path: path).content
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
