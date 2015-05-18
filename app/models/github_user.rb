class GithubUser < ActiveRecord::Base
  has_many :github_contributions
  has_many :github_repositories, primary_key: :github_id, foreign_key: :owner_id
  has_many :source_github_repositories, -> { where fork: false }, class: GithubRepository, primary_key: :github_id, foreign_key: :owner_id
  has_many :dependencies, through: :source_github_repositories
  has_many :favourite_projects, -> { group('projects.id').order("COUNT(projects.id) DESC") }, through: :dependencies, source: :project

  scope :visible, -> { where(hidden: false) }

  def avatar_url(size = 60)
    "https://avatars.githubusercontent.com/u/#{github_id}?size=#{size}"
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

  def dowload_from_github
    update_attributes(github_client.user(github_id).to_hash.slice(:login, :name, :company, :blog, :location))
  rescue Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway => e
    nil
  end
end
