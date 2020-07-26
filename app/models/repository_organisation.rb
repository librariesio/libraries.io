class RepositoryOrganisation < ApplicationRecord
  API_FIELDS = [:name, :login, :blog, :email, :location, :bio]

  has_many :repositories
  has_many :source_repositories, -> { where fork: false }, anonymous_class: Repository
  has_many :open_source_repositories, -> { where fork: false, private: false }, anonymous_class: Repository
  has_many :dependencies, through: :open_source_repositories
  has_many :favourite_projects, -> { group('projects.id').order(Arel.sql("COUNT(projects.id) DESC, projects.rank DESC")) }, through: :dependencies, source: :project
  has_many :all_dependent_repos, -> { group('repositories.id') }, through: :favourite_projects, source: :repository
  has_many :contributors, -> { group('repository_users.id').order(Arel.sql("sum(contributions.count) DESC")) }, through: :open_source_repositories, source: :contributors
  has_many :projects, through: :open_source_repositories

  # eager load this module to avoid clashing with Gitlab gem in development
  RepositoryOwner::Gitlab

  validates :uuid, presence: true
  validate :login_uniqueness_with_case_insensitive_host, if: lambda { self.login_changed? }
  validates :uuid, uniqueness: {scope: :host_type}, if: lambda { self.uuid_changed? }

  after_commit :async_sync, on: :create

  scope :most_repos, -> { joins(:open_source_repositories).select('repository_organisations.*, count(repositories.id) AS repo_count').group('repository_organisations.id').order(Arel.sql('repo_count DESC')) }
  scope :most_stars, -> { joins(:open_source_repositories).select('repository_organisations.*, sum(repositories.stargazers_count) AS star_count, count(repositories.id) AS repo_count').group('repository_organisations.id').order(Arel.sql('star_count DESC')) }
  scope :newest, -> { joins(:open_source_repositories).select('repository_organisations.*, count(repositories.id) AS repo_count').group('repository_organisations.id').order(Arel.sql('created_at DESC')).having('count(repositories.id) > 0') }
  scope :visible, -> { where(hidden: false) }
  scope :with_login, -> { where("repository_organisations.login <> ''") }
  scope :host, lambda{ |host_type| where('lower(repository_organisations.host_type) = ?', host_type.try(:downcase)) }
  scope :login, lambda{ |login| where('lower(repository_organisations.login) = ?', login.try(:downcase)) }

  delegate :avatar_url, :repository_url, :top_favourite_projects, :top_contributors,
           :to_s, :to_param, :github_id, :download_org_from_host, :download_orgs,
           :download_org_from_host_by_login, :download_repos, :download_members,
           :check_status, to: :repository_owner

  def login_uniqueness_with_case_insensitive_host
    if RepositoryOrganisation.host(host_type).login(login).exists?
      errors.add(:login, "must be unique")
    end
  end

  def repository_owner
    @repository_owner ||= RepositoryOwner.const_get(host_type.capitalize).new(self)
  end

  def meta_tags
    {
      title: "#{self} on #{host_type}",
      description: "#{host_type} repositories created by #{self}",
      image: avatar_url(200)
    }
  end

  def contributions
    Contribution.none
  end

  def org?
    true
  end

  def company
    nil
  end

  def user_type
    'Organisation'
  end

  def followers
    0
  end

  def following
    0
  end

  def self.create_from_host(host_type, org_hash)
    RepositoryOwner.const_get(host_type.capitalize).create_org(org_hash)
  end

  def async_sync
    RepositoryUpdateOrgWorker.perform_async(self.host_type, self.login)
  end

  def sync
    check_status
    return unless persisted?
    download_org_from_host
    download_repos
    download_members
    update_attributes(last_synced_at: Time.now)
  end

  def recently_synced?
    last_synced_at && last_synced_at > 1.day.ago
  end

  def manual_sync
    async_sync
    self.last_synced_at = Time.zone.now
    save
  end

  def find_repositories
    Repository.host(host_type).where('full_name ILIKE ?', "#{login}/%").update_all(repository_user_id: nil, repository_organisation_id: self.id)
  end
end
