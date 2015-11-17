class User < ActiveRecord::Base
  include Recommendable

  has_many :subscriptions, dependent: :destroy
  has_many :subscribed_projects, through: :subscriptions, source: :project
  has_many :repository_subscriptions, dependent: :destroy
  has_many :api_keys, dependent: :destroy
  has_many :repository_permissions, dependent: :destroy
  has_many :adminable_repository_permissions, -> { where admin: true }, anonymous_class: RepositoryPermission
  has_many :adminable_github_repositories, through: :adminable_repository_permissions, source: :github_repository
  has_many :adminable_github_orgs, -> { group('github_organisations.id') }, through: :adminable_github_repositories, source: :github_organisation
  has_many :github_repositories, primary_key: :uid, foreign_key: :owner_id
  has_many :source_github_repositories, -> { where fork: false }, anonymous_class: GithubRepository, primary_key: :github_id, foreign_key: :owner_id

  has_many :watched_github_repositories, source: :github_repository, through: :repository_subscriptions
  has_many :watched_dependencies, through: :watched_github_repositories, source: :dependencies
  has_many :watched_dependent_projects, -> { group('projects.id') }, through: :watched_dependencies, source: :project

  has_many :dependencies, through: :source_github_repositories
  has_many :all_dependencies, through: :github_repositories, source: :dependencies
  has_many :all_dependent_projects, -> { group('projects.id') }, through: :all_dependencies, source: :project

  has_many :favourite_projects, -> { group('projects.id').order("COUNT(projects.id) DESC") }, through: :dependencies, source: :project
  has_one :github_user, primary_key: :uid, foreign_key: :github_id

  has_many :project_mutes
  has_many :muted_projects, through: :project_mutes, source: :project

  has_many :payola_subscriptions, anonymous_class: Payola::Subscription, as: :owner
  has_many :project_suggestions

  after_commit :update_repo_permissions_async, :download_self, :create_api_key, on: :create

  ADMIN_USERS = ['andrew', 'barisbalic', 'malditogeek', 'olizilla', 'thattommyhall']

  validates_presence_of :email, :on => :update
  validates_format_of :email, :with => /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/, :on => :update

  def has_active_subscription?
    active_subscription.present?
  end

  def current_plan
    @current_plan ||= payola_subscriptions.active.select{|sub| sub.plan.present? }.sort{|sub| sub.plan.amount }.last.try(:plan)
  end

  def active_subscription
    @active_subscription ||= payola_subscriptions.active.select{|sub| sub.plan.present? }.sort{|sub| sub.plan.amount }
  end

  def max_private_repo_count
    current_plan.try(:repo_count) || 0
  end

  def current_private_repo_count
    watched_github_repositories.where(private: true).count
  end

  def reached_private_repo_limit?
    current_private_repo_count >= max_private_repo_count
  end

  def can_enable_private_repo_tracking?
    private_repo_token.blank? && admin?
  end

  def can_track_private_repos?
    admin? || has_active_subscription?
  end

  def needs_to_enable_github_access?
    private_repo_token.blank? && public_repo_token.blank?
  end

  def can_watch?(repo)
    if repo.private?
      can_track_private_repos? && !reached_private_repo_limit?
    else
      !needs_to_enable_github_access?
    end
  end

  def your_dependent_repos(project)
    ids = all_dependencies.where(project_id: project.id).includes(:manifest).map{|dep| dep.manifest.github_repository_id }
    github_repositories.where(id: ids).order('stargazers_count DESC')
  end

  def all_subscribed_projects
    Project.where(id: all_subscribed_project_ids)
  end

  def to_s
    full_name
  end

  def full_name
    name.presence || nickname
  end

  def all_subscribed_project_ids
    (subscribed_projects.pluck(:id) + watched_dependent_projects.pluck(:id)).uniq
  end

  def all_subscribed_versions
    Version.where(project_id: all_subscribed_project_ids)
  end

  def admin?
    ADMIN_USERS.include?(nickname)
  end

  def monitoring_enabled?
    admin? || public_repo_token.present? || private_repo_token.present?
  end

  def can_monitor?(github_repository)
    repository_permissions.where(github_repository: github_repository).where(admin: true).any?
  end

  def create_api_key
    api_keys.create
  end

  def api_key
    api_keys.first.try(:access_token)
  end

  def github_settings_url
    if private_repo_token.present?
      key = ENV['GITHUB_PRIVATE_KEY']
    elsif
      key = ENV['GITHUB_PUBLIC_KEY']
    else
      key = ENV['GITHUB_KEY']
    end
    "https://github.com/settings/connections/applications/#{key}"
  end

  def self.create_from_auth_hash(hash)
    create!(AuthHash.new(hash).user_info)
  end

  def assign_from_auth_hash(hash)
    ignored_fields = new_record? ? [] : %i(email)
    update_attributes(AuthHash.new(hash).user_info.except(*ignored_fields))
  end

  def self.find_by_auth_hash(hash)
    conditions = AuthHash.new(hash).user_info.slice(:provider, :uid)
    where(conditions).first
  end

  def token
    private_repo_token.presence || public_repo_token.presence || read_attribute(:token)
  end

  def github_client
    AuthToken.new_client(token)
  end

  def avatar_url(size = 60)
    "https://avatars.githubusercontent.com/u/#{uid}?size=#{size}"
  end

  def github_url
    "https://github.com/#{nickname}"
  end

  def update_repo_permissions_async
    SyncPermissionsWorker.perform_async(self.id)
  end

  def update_repo_permissions
    self.update_column(:currently_syncing, true)
    download_orgs
    r = github_client.repos

    current_repo_ids = []

    existing_permissions = repository_permissions.all
    new_repo_ids = r.map(&:id)
    existing_repos = GithubRepository.where(github_id: new_repo_ids).select(:id, :github_id)

    r.each do |repo|
      unless github_repo = existing_repos.find{|r| r.github_id == repo.id}
        github_repo = GithubRepository.find_by('lower(full_name) = ?', repo.full_name.downcase) || GithubRepository.create_from_hash(repo)
      end
      current_repo_ids << github_repo.id unless github_repo.nil?

      unless rp = existing_permissions.find{|p| p.github_repository_id == github_repo.id}
        rp = repository_permissions.build(github_repository_id: github_repo.id)
      end
      rp.admin = repo.permissions.admin
      rp.push = repo.permissions.push
      rp.pull = repo.permissions.pull
      rp.save! if rp.changed?
    end

    # delete missing permissions
    existing_repo_ids = repository_permissions.pluck(:github_repository_id)
    remove_ids = existing_repo_ids - current_repo_ids
    repository_permissions.where(github_repository_id: remove_ids).delete_all if remove_ids.any?

  rescue Octokit::Unauthorized, Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway => e
    nil
  ensure
    self.update_columns(last_synced_at: Time.now, currently_syncing: false)
  end

  def download_self
    user = GithubUser.find_or_create_by(github_id: self.uid) do |u|
      u.login = self.nickname
      u.user_type = 'User'
    end
    GithubUpdateUserWorker.perform_async(nickname)
  end

  def download_orgs
    github_client.orgs.each do |org|
      GithubCreateOrgWorker.perform_async(org.login)
    end
  rescue Octokit::Unauthorized, Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway => e
    nil
  end

  def subscribe_to_repo(github_repository)
    hook = github_repository.create_webhook(token)
    repository_subscriptions.find_or_create_by(github_repository_id: github_repository.id, hook_id: hook.try(:id))
  end

  def unsubscribe_from_repo(github_repository)
    sub = subscribed_to_repo?(github_repository)
    sub.destroy
  end

  def subscribed_to?(project)
    subscriptions.find_by_project_id(project.id)
  end

  def subscribed_to_repo?(github_repository)
    repository_subscriptions.find_by_github_repository_id(github_repository.id)
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

  def can_read?(github_repository)
    repository_permissions.where(github_repository: github_repository).where(pull: true).any?
  end
end
