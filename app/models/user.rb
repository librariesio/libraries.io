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
  has_many :adminable_repository_organisations, -> { group('repository_organisations.id') }, through: :adminable_repositories, source: :repository_organisation
  has_many :source_repositories, -> { where fork: false }, anonymous_class: Repository, through: :repository_users
  has_many :public_repositories, -> { where private: false }, anonymous_class: Repository, through: :repository_users

  has_many :watched_repositories, source: :repository, through: :repository_subscriptions

  has_many :dependencies, through: :source_repositories
  has_many :really_all_dependencies, through: :all_repositories, source: :dependencies
  has_many :all_dependent_projects, -> { group('projects.id') }, through: :really_all_dependencies, source: :project
  has_many :all_dependent_repos, -> { group('repositories.id') }, through: :all_dependent_projects, source: :repository

  has_many :favourite_projects, -> { group('projects.id').order("COUNT(projects.id) DESC, projects.rank DESC") }, through: :dependencies, source: :project

  has_many :project_mutes, dependent: :delete_all
  has_many :muted_projects, through: :project_mutes, source: :project
  has_many :project_suggestions

  scope :optin, -> { where(optin: true) }

  after_commit :update_repo_permissions_async, :download_self, :create_api_key, on: :create

  ADMIN_USERS = ['havocp', 'katzj']

  validates_presence_of :email, :on => :update
  validates_format_of :email, :with => /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/, :on => :update

  def assign_from_auth_hash(hash)
    return unless new_record?
    update_attributes({email: hash.fetch('info', {}).fetch('email', nil)})
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
    repo_subs = repository_subscriptions.pluck(:repository_id)
    Project.where(id: RepositoryDependency.where(repository_id: repo_subs).pluck(:project_id).uniq)
  end

  def all_subscribed_project_ids
    (subscribed_projects.visible.pluck(:id) + watched_dependent_projects.visible.pluck(:id)).uniq
  end

  def all_subscribed_versions
    Version.where(project_id: all_subscribed_project_ids)
  end

  def admin?
    github_enabled? && ADMIN_USERS.include?(nickname)
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
