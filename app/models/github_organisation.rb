class GithubOrganisation < ActiveRecord::Base
  API_FIELDS = [:name, :login, :blog, :email, :location, :description]

  has_many :github_repositories
  has_many :source_github_repositories, -> { where fork: false }, anonymous_class: GithubRepository
  has_many :dependencies, through: :source_github_repositories
  has_many :favourite_projects, -> { group('projects.id').order("COUNT(projects.id) DESC") }, through: :dependencies, source: :project
  has_many :contributors, -> { group('github_users.id').order("COUNT(github_users.id) DESC") }, through: :github_repositories, source: :contributors

  validates_uniqueness_of :github_id, :login

  after_commit :download_repos, on: :create

  scope :most_repos, -> { joins(:source_github_repositories).select('github_organisations.*, count(github_repositories.id) AS repo_count').group('github_organisations.id').order('repo_count DESC') }
  scope :most_stars, -> { joins(:source_github_repositories).select('github_organisations.*, sum(github_repositories.stargazers_count) AS star_count, count(github_repositories.id) AS repo_count').group('github_organisations.id').order('star_count DESC') }
  scope :newest, -> { joins(:source_github_repositories).select('github_organisations.*, count(github_repositories.id) AS repo_count').group('github_organisations.id').order('created_at DESC').having('count(github_repositories.id) > 0') }

  def github_contributions
    GithubContribution.none
  end

  def org?
    true
  end

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

  def company
    nil
  end

  def self.create_from_github(login_or_id)
    begin
      r = AuthToken.client.org(login_or_id).to_hash
      return false if r.blank?
      g = GithubOrganisation.find_or_initialize_by(github_id: r[:id])
      g.github_id = r[:id]
      g.assign_attributes r.slice(*GithubOrganisation::API_FIELDS)
      g.save
      g
    rescue Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway => e
      p e
      false
    end
  end

  def download_repos
    AuthToken.client.org_repos(login).each do |repo|
      GithubCreateWorker.perform_async(repo.full_name)
    end
  rescue Octokit::Unauthorized, Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway => e
    nil
  end

  # TODO download members
end
