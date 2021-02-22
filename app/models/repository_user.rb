# frozen_string_literal: true
class RepositoryUser < ApplicationRecord
  has_many :contributions, dependent: :delete_all
  has_many :repositories
  has_many :source_repositories, -> { where fork: false }, anonymous_class: Repository
  has_many :open_source_repositories, -> { where fork: false, private: false }, anonymous_class: Repository
  has_many :dependencies, through: :open_source_repositories
  has_many :favourite_projects, -> { group('projects.id').order(Arel.sql("COUNT(projects.id) DESC, projects.rank DESC")) }, through: :dependencies, source: :project
  has_many :all_dependent_repos, -> { group('repositories.id') }, through: :favourite_projects, source: :repository
  has_many :contributed_repositories, -> { Repository.source.open_source }, through: :contributions, source: :repository
  has_many :contributed_projects, through: :contributed_repositories, source: :projects
  has_many :contributors, -> { group('repository_users.id').order(Arel.sql("sum(contributions.count) DESC")) }, through: :open_source_repositories, source: :contributors
  has_many :fellow_contributors, -> (object){ where.not(id: object.id).group('repository_users.id').order(Arel.sql("COUNT(repository_users.id) DESC")) }, through: :contributed_repositories, source: :contributors
  has_many :projects, through: :open_source_repositories
  has_many :identities

  # eager load this module to avoid clashing with Gitlab gem in development
  RepositoryOwner::Gitlab

  has_many :issues

  validate :login_uniqueness_with_case_insensitive_host, if: lambda { self.login_changed? }
  validates :uuid, uniqueness: {scope: :host_type}, if: lambda { self.uuid_changed? }
  validates :uuid, presence: true

  after_commit :async_sync, on: :create

  scope :visible, -> { where(hidden: false) }
  scope :with_login, -> { where("repository_users.login <> ''") }
  scope :host, lambda{ |host_type| where('lower(repository_users.host_type) = ?', host_type.try(:downcase)) }
  scope :login, lambda{ |login| where('lower(repository_users.login) = ?', login.try(:downcase)) }

  delegate :avatar_url, :repository_url, :top_favourite_projects, :top_contributors,
           :to_s, :to_param, :github_id, :download_user_from_host, :download_orgs,
           :download_user_from_host_by_login, :download_repos, :check_status, to: :repository_owner

 def login_uniqueness_with_case_insensitive_host
   if RepositoryUser.host(host_type).login(login).exists?
     errors.add(:login, "must be unique")
   end
 end

  def repository_owner
    @repository_owner ||= RepositoryOwner.const_get(host_type.capitalize).new(self)
  end

  def meta_tags
    {
      title: "#{self} on #{host_type}",
      description: "#{host_type} repositories created and contributed to by #{self}",
      image: avatar_url(200)
    }
  end

  def open_source_contributions
    contributions.joins(:repository).where("repositories.fork = ? AND repositories.private = ?", false, false)
  end

  def org?
    false
  end

  def async_sync
    RepositoryUpdateUserWorker.perform_async(self.host_type, self.login)
  end

  def sync
    check_status
    return unless persisted?
    download_user_from_host
    download_orgs
    download_repos
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

  def hide
    update!(hidden: true)
  end

  def self.create_from_host(host_type, user_hash)
    RepositoryOwner.const_get(host_type.capitalize).create_user(user_hash)
  end
end
