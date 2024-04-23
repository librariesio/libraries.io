# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                :integer          not null, primary key
#  currently_syncing :boolean          default(FALSE), not null
#  email             :string
#  emails_enabled    :boolean          default(TRUE)
#  is_admin          :boolean          default(FALSE), not null
#  last_login_at     :datetime
#  last_synced_at    :datetime
#  optin             :boolean          default(FALSE)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_users_on_created_at  (created_at)
#
class User < ApplicationRecord
  include Recommendable
  include GithubIdentity
  include Monitoring

  has_many :identities, dependent: :destroy
  has_many :viewable_identities, -> { viewable }, anonymous_class: Identity
  has_many :repository_users, through: :identities

  has_many :subscriptions, dependent: :destroy
  has_many :subscribed_projects, through: :subscriptions, source: :project
  has_many :repository_subscriptions, dependent: :destroy
  has_many :api_keys, dependent: :destroy
  has_many :repository_permissions, dependent: :destroy
  has_many :all_repositories, through: :repository_permissions, source: :repository
  has_many :adminable_repository_permissions, -> { where admin: true }, anonymous_class: RepositoryPermission
  has_many :adminable_repositories, through: :adminable_repository_permissions, source: :repository
  has_many :adminable_repository_organisations, -> { group("repository_organisations.id") }, through: :adminable_repositories, source: :repository_organisation
  has_many :source_repositories, -> { where fork: false }, anonymous_class: Repository, through: :repository_users
  has_many :public_repositories, -> { where private: false }, anonymous_class: Repository, through: :repository_users

  has_many :watched_repositories, source: :repository, through: :repository_subscriptions

  has_many :project_mutes, dependent: :delete_all
  has_many :muted_projects, through: :project_mutes, source: :project
  has_many :project_suggestions

  scope :optin, -> { where(optin: true) }

  after_commit :update_repo_permissions_async, :download_self, :create_api_key, on: :create

  validates_presence_of :email, on: :update
  validates_format_of :email, with: /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/, on: :update

  # TODO: can this be an association again if we made projects_dependencies a Repository association again?
  def dependencies
    source_repositories
      .flat_map(&:projects_dependencies)
  end

  # TODO: can this be an association again if we made projects_dependencies a Repository association again?
  def really_all_dependencies
    all_repositories
      .flat_map(&:projects_dependencies)
  end

  # TODO: can this be an association again if we made projects_dependencies a Repository association again?
  def favourite_projects
    dep_ids = source_repositories
      .flat_map { |r| r.projects_dependencies(only_visible: true).map(&:id) }
      .uniq

    Project
      .joins(:dependents)
      .where(dependencies: { id: dep_ids })
      .group("projects.id")
      .order(Arel.sql("COUNT(projects.id) DESC, projects.rank DESC"))
  end

  def assign_from_auth_hash(hash)
    return unless new_record?

    update({ email: hash.fetch("info", {}).fetch("email", nil) })
  end

  def main_identity
    @main_identity ||= viewable_identities.first
  end

  def to_param
    main_identity.try(:to_param)
  end

  def avatar_url(size = 60)
    main_identity.try(:avatar_url, size)
  end

  def nickname
    main_identity.try(:nickname).presence
  end

  def all_subscribed_projects
    Project.where(id: all_subscribed_project_ids)
  end

  def to_s
    nickname
  end

  def watched_dependent_projects
    repository_subscriptions
      .map(&:repository)
      .map { |r| r.projects_dependencies(includes: [:project], only_visible: true).map(&:project) }
      .flatten
      .uniq
  end

  def all_subscribed_project_ids
    (subscribed_projects.visible.pluck(:id) + watched_dependent_projects.pluck(:id)).uniq
  end

  def all_subscribed_versions
    Version.where(project_id: all_subscribed_project_ids)
  end

  def admin?
    github_enabled? && is_admin?
  end

  def admin_or_internal?
    admin? || current_api_key&.is_internal
  end

  def create_api_key
    api_keys.create
  end

  def api_key
    current_api_key.try(:access_token)
  end

  def current_api_key
    api_keys.active.first
  end

  def muted?(project)
    project_mutes.where(project_id: project.id).any?
  end

  def mute(project)
    project_mutes.find_or_create_by(project: project)
  end

  def unmute(project)
    project_mutes.where(project_id: project.id).delete_all
  end
end
