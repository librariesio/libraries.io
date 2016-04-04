class GithubIssue < ActiveRecord::Base
  belongs_to :github_repository
  belongs_to :github_user

  API_FIELDS = [:number, :state, :title, :body, :locked, :closed_at]

  def github_client(token = nil)
    AuthToken.fallback_client(token)
  end

  # def update_from_github(token = nil)
  #   begin
  #     r = github_client(token).repo(id_or_name, accept: 'application/vnd.github.drax-preview+json').to_hash
  #     return if r.nil? || r.empty?
  #     self.github_id = r[:id]
  #     self.full_name = r[:full_name] if self.full_name.downcase != r[:full_name].downcase
  #     self.owner_id = r[:owner][:id]
  #     self.license = Project.format_license(r[:license][:key]) if r[:license]
  #     self.source_name = r[:parent][:full_name] if r[:fork]
  #     assign_attributes r.slice(*API_FIELDS)
  #     save! if self.changed?
  #   rescue Octokit::Unauthorized, Octokit::InvalidRepository, Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway => e
  #     nil
  #   end
  # end

  # def self.create_from_github(full_name, token = nil)
  #   github_client = AuthToken.new_client(token)
  #   repo_hash = github_client.repo(full_name, accept: 'application/vnd.github.drax-preview+json').to_hash
  #   return false if repo_hash.nil? || repo_hash.empty?
  #   create_from_hash(repo_hash)
  # rescue Octokit::Unauthorized, Octokit::InvalidRepository, Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Conflict, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway => e
  #   nil
  # end
  #
  def self.create_from_hash(repo, issue_hash)
    issue_hash = issue_hash.to_hash
    i = repo.github_issues.find_or_create_by(github_id: issue_hash[:id])
    i.github_user_id = issue_hash[:user][:id]
    i.github_repository_id = repo.id
    i.comments_count = issue_hash[:comments]
    i.assign_attributes issue_hash.slice(*GithubIssue::API_FIELDS)
    i.save! if i.changed?
    i
  end
end
