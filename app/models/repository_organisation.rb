# frozen_string_literal: true

# == Schema Information
#
# Table name: repository_organisations
#
#  id             :integer          not null, primary key
#  bio            :string
#  blog           :string
#  email          :string
#  hidden         :boolean          default(FALSE)
#  host_type      :string
#  last_synced_at :datetime
#  location       :string
#  login          :string
#  name           :string
#  uuid           :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_repository_organisations_on_created_at                   (created_at)
#  index_repository_organisations_on_hidden                       (hidden)
#  index_repository_organisations_on_host_type_and_uuid           (host_type,uuid) UNIQUE
#  index_repository_organisations_on_lower_host_type_lower_login  (lower((host_type)::text), lower((login)::text)) UNIQUE
#
class RepositoryOrganisation < ApplicationRecord
  API_FIELDS = %i[name login blog email location bio].freeze

  has_many :repositories
  has_many :source_repositories, -> { where fork: false }, anonymous_class: Repository
  has_many :open_source_repositories, -> { where fork: false, private: false }, anonymous_class: Repository
  has_many :contributors, -> { group("repository_users.id").order(Arel.sql("sum(contributions.count) DESC")) }, through: :open_source_repositories, source: :contributors
  has_many :projects, through: :open_source_repositories

  # eager load this module to avoid clashing with Gitlab gem in development
  RepositoryOwner::Gitlab # rubocop: disable Lint/Void

  validates :uuid, presence: true

  after_commit :async_sync, on: :create

  scope :most_repos, -> { joins(:open_source_repositories).select("repository_organisations.*, count(repositories.id) AS repo_count").group("repository_organisations.id").order(Arel.sql("repo_count DESC")) }
  scope :most_stars, -> { joins(:open_source_repositories).select("repository_organisations.*, sum(repositories.stargazers_count) AS star_count, count(repositories.id) AS repo_count").group("repository_organisations.id").order(Arel.sql("star_count DESC")) }
  scope :newest, -> { joins(:open_source_repositories).select("repository_organisations.*, count(repositories.id) AS repo_count").group("repository_organisations.id").order(Arel.sql("created_at DESC")).having("count(repositories.id) > 0") }
  scope :visible, -> { where(hidden: false) }
  scope :with_login, -> { where("repository_organisations.login <> ''") }
  scope :host, ->(host_type) { where("lower(repository_organisations.host_type) = ?", host_type.try(:downcase)) }
  scope :login, ->(login) { where("lower(repository_organisations.login) = ?", login.try(:downcase)) }

  delegate :avatar_url, :repository_url, :top_favourite_projects, :top_contributors,
           :to_s, :to_param, :github_id, :download_org_from_host, :download_orgs,
           :download_org_from_host_by_login, :download_repos, :download_members,
           :check_status, to: :repository_owner

  # TODO: can this be an association again if we made projects_dependencies a Repository association again?
  def favourite_projects
    dep_ids = open_source_repositories
      .flat_map { |r| r.projects_dependencies(only_visible: true).map(&:id) }
      .uniq

    Project
      .joins(:dependents)
      .where(dependencies: { id: dep_ids })
      .group("projects.id")
      .order(Arel.sql("COUNT(projects.id) DESC, projects.rank DESC"))
  end

  def repository_owner
    @repository_owner ||= RepositoryOwner.const_get(host_type.capitalize).new(self)
  end

  def meta_tags
    {
      title: "#{self} on #{host_type}",
      description: "#{host_type} repositories created by #{self}",
      image: avatar_url(200),
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
    "Organisation"
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
    RepositoryUpdateOrgWorker.perform_async(host_type, login)
  end

  def sync
    check_status
    return unless persisted?

    download_org_from_host
    download_repos
    download_members
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

  def find_repositories
    Repository.host(host_type).where("full_name ILIKE ?", "#{login}/%").update_all(repository_user_id: nil, repository_organisation_id: id)
  end
end
