class GithubUser < ActiveRecord::Base
  has_many :github_contributions, dependent: :destroy
  has_many :github_repositories, primary_key: :github_id, foreign_key: :owner_id
  has_many :source_github_repositories, -> { where fork: false }, anonymous_class: GithubRepository, primary_key: :github_id, foreign_key: :owner_id
  has_many :dependencies, through: :source_github_repositories
  has_many :favourite_projects, -> { group('projects.id').order("COUNT(projects.id) DESC") }, through: :dependencies, source: :project

  validates_uniqueness_of :github_id, :login

  after_commit :download_orgs, on: :create

  scope :visible, -> { where(hidden: false) }

  def avatar_url(size = 60)
    "https://avatars.githubusercontent.com/u/#{github_id}?size=#{size}"
  end

  def org?
    false
  end

  def github_url
    "https://github.com/#{login}"
  end

  def to_s
    name.presence || login
  end

  def to_param
    login
  end

  def description
    nil
  end

  def github_client
    AuthToken.client
  end

  def download_from_github
    update_attributes(github_client.user(github_id).to_hash.slice(:login, :name, :company, :blog, :location))
  rescue Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway => e
    nil
  end

  def download_orgs
    github_client.orgs(login).each do |org|
      GithubCreateOrgWorker.perform_async(org.login)
    end
    true
  rescue Octokit::Unauthorized, Octokit::UnprocessableEntity, Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway => e
    nil
  end

  def download_repos
    AuthToken.client.search_repos("user:#{login}").items.each do |repo|
      GithubRepository.create_from_hash repo.to_hash
    end

    true
  rescue Octokit::Unauthorized, Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway => e
    nil
  end
end
