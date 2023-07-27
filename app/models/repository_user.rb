# frozen_string_literal: true

# == Schema Information
#
# Table name: repository_users
#
#  id             :integer          not null, primary key
#  bio            :string
#  blog           :string
#  company        :string
#  email          :string
#  followers      :integer
#  following      :integer
#  hidden         :boolean          default(FALSE)
#  host_type      :string
#  last_synced_at :datetime
#  location       :string
#  login          :string
#  name           :string
#  user_type      :string
#  uuid           :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_repository_users_on_created_at                   (created_at)
#  index_repository_users_on_hidden                       (hidden)
#  index_repository_users_on_hidden_and_last_synced_at    (hidden,last_synced_at)
#  index_repository_users_on_host_type_and_uuid           (host_type,uuid) UNIQUE
#  index_repository_users_on_lower_host_type_lower_login  (lower((host_type)::text), lower((login)::text)) UNIQUE
#
class RepositoryUser < ApplicationRecord
  has_many :contributions, dependent: :delete_all
  has_many :repositories
  has_many :source_repositories, -> { where fork: false }, anonymous_class: Repository
  has_many :open_source_repositories, -> { where fork: false, private: false }, anonymous_class: Repository
  has_many :dependencies, through: :open_source_repositories
  has_many :favourite_projects, -> { group("projects.id").order(Arel.sql("COUNT(projects.id) DESC, projects.rank DESC")) }, through: :dependencies, source: :project
  has_many :all_dependent_repos, -> { group("repositories.id") }, through: :favourite_projects, source: :repository
  has_many :contributed_repositories, -> { Repository.source.open_source }, through: :contributions, source: :repository
  has_many :contributed_projects, through: :contributed_repositories, source: :projects
  has_many :contributors, -> { group("repository_users.id").order(Arel.sql("sum(contributions.count) DESC")) }, through: :open_source_repositories, source: :contributors
  has_many :fellow_contributors, ->(object) { where.not(id: object.id).group("repository_users.id").order(Arel.sql("COUNT(repository_users.id) DESC")) }, through: :contributed_repositories, source: :contributors
  has_many :projects, through: :open_source_repositories
  has_many :identities

  # eager load this module to avoid clashing with Gitlab gem in development
  RepositoryOwner::Gitlab # rubocop: disable Lint/Void

  validate :login_uniqueness_with_case_insensitive_host, if: -> { login_changed? }
  validates :uuid, uniqueness: { scope: :host_type }, if: -> { uuid_changed? }
  validates :uuid, presence: true

  after_commit :async_sync, on: :create

  scope :visible, -> { where(hidden: false) }
  scope :with_login, -> { where("repository_users.login <> ''") }
  scope :host, ->(host_type) { where("lower(repository_users.host_type) = ?", host_type.try(:downcase)) }
  scope :login, ->(login) { where("lower(repository_users.login) = ?", login.try(:downcase)) }

  delegate :avatar_url, :repository_url, :top_favourite_projects, :top_contributors,
           :to_s, :to_param, :github_id, :download_user_from_host, :download_orgs,
           :download_user_from_host_by_login, :download_repos, :check_status, to: :repository_owner

  def login_uniqueness_with_case_insensitive_host
    errors.add(:login, "must be unique") if RepositoryUser.host(host_type).login(login).exists?
  end

  def repository_owner
    @repository_owner ||= RepositoryOwner.const_get(host_type.capitalize).new(self)
  end

  def meta_tags
    {
      title: "#{self} on #{host_type}",
      description: "#{host_type} repositories created and contributed to by #{self}",
      image: avatar_url(200),
    }
  end

  def open_source_contributions
    contributions.joins(:repository).where("repositories.fork = ? AND repositories.private = ?", false, false)
  end

  def org?
    false
  end

  def async_sync
    RepositoryUpdateUserWorker.perform_async(host_type, login)
  end

  def sync
    check_status
    return unless persisted?

    download_user_from_host
    download_orgs
    download_repos
    update(last_synced_at: Time.now)
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
