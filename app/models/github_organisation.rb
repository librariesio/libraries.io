class GithubOrganisation < ActiveRecord::Base
  API_FIELDS = [:name, :login, :blog, :email, :location, :description]

  has_many :github_repositories
  has_many :source_github_repositories, -> { where fork: false }, anonymous_class: GithubRepository
  has_many :dependencies, through: :source_github_repositories
  has_many :favourite_projects, -> { group('projects.id').order("COUNT(projects.id) DESC") }, through: :dependencies, source: :project

  after_commit :download_repos, on: :create

  def github_contributions
    GithubContribution.none
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
