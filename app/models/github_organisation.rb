class GithubOrganisation < ActiveRecord::Base
  API_FIELDS = [:name, :login, :blog, :email, :location, :description]

  has_many :github_repositories
  has_many :source_github_repositories, -> { where fork: false }, anonymous_class: GithubRepository
  has_many :open_source_github_repositories, -> { where fork: false, private: false }, anonymous_class: GithubRepository
  has_many :dependencies, through: :open_source_github_repositories
  has_many :favourite_projects, -> { group('projects.id').order("COUNT(projects.id) DESC") }, through: :dependencies, source: :project
  has_many :contributors, -> { group('github_users.id').order("sum(github_contributions.count) DESC") }, through: :open_source_github_repositories, source: :contributors

  validates :login, uniqueness: true, if: lambda { self.login_changed? }
  validates :github_id, uniqueness: true, if: lambda { self.github_id_changed? }

  after_commit :async_sync, on: :create

  scope :most_repos, -> { joins(:open_source_github_repositories).select('github_organisations.*, count(github_repositories.id) AS repo_count').group('github_organisations.id').order('repo_count DESC') }
  scope :most_stars, -> { joins(:open_source_github_repositories).select('github_organisations.*, sum(github_repositories.stargazers_count) AS star_count, count(github_repositories.id) AS repo_count').group('github_organisations.id').order('star_count DESC') }
  scope :newest, -> { joins(:open_source_github_repositories).select('github_organisations.*, count(github_repositories.id) AS repo_count').group('github_organisations.id').order('created_at DESC').having('count(github_repositories.id) > 0') }
  scope :visible, -> { where(hidden: false) }

  def github_contributions
    GithubContribution.none
  end

  def top_favourite_projects
    Project.where(id: top_favourite_project_ids).maintained.order("position(','||projects.id::text||',' in '#{top_favourite_project_ids.join(',')}')")
  end

  def top_favourite_project_ids
    Rails.cache.fetch "org:#{self.id}:top_favourite_project_ids", :expires_in => 1.week do
      favourite_projects.limit(10).pluck(:id)
    end
  end

  def top_contributors
    GithubUser.where(id: top_contributor_ids).order("position(','||github_users.id::text||',' in '#{top_contributor_ids.join(',')}')")
  end

  def top_contributor_ids
    Rails.cache.fetch "org:#{self.id}:top_contributor_ids", :expires_in => 1.week do
      contributors.visible.limit(50).pluck(:id)
    end
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

  def github_client
    AuthToken.client
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

  def async_sync
    GithubUpdateOrgWorker.perform_async(self.login)
  end

  def sync
    download_from_github
    download_repos
    update_attributes(last_synced_at: Time.now)
  end

  def download_from_github
    update_attributes(github_client.org(github_id).to_hash.slice(:login, :name, :email, :blog, :location, :description))
  rescue Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway => e
    nil
  end

  def download_repos
    github_client.org_repos(login).each do |repo|
      GithubCreateWorker.perform_async(repo.full_name)
    end
  rescue Octokit::Unauthorized, Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway => e
    nil
  end

  # TODO download members
end
