class User < ActiveRecord::Base
  has_many :subscriptions
  has_many :repository_subscriptions
  has_many :api_keys
  has_many :repository_permissions
  has_many :adminable_repository_permissions, -> { where admin: true }, anonymous_class: RepositoryPermission
  has_many :adminable_github_repositories, through: :adminable_repository_permissions, source: :github_repository
  has_many :github_repositories, primary_key: :uid, foreign_key: :owner_id
  has_many :source_github_repositories, -> { where fork: false }, anonymous_class: GithubRepository, primary_key: :github_id, foreign_key: :owner_id
  has_many :dependencies, through: :source_github_repositories
  has_many :favourite_projects, -> { group('projects.id').order("COUNT(projects.id) DESC") }, through: :dependencies, source: :project
  has_one :github_user, primary_key: :uid, foreign_key: :github_id

  after_commit :create_api_key, :ping_andrew, :download_orgs, :update_repo_permissions_async, on: :create

  ADMIN_USERS = ['andrew', 'barisbalic', 'malditogeek', 'olizilla', 'thattommyhall']

  validates_presence_of :email, :on => :update
  validates_format_of :email, :with => /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/, :on => :update

  def admin?
    ADMIN_USERS.include?(nickname)
  end

  def ping_andrew
    PushoverNewUserWorker.perform_async(self.id)
  end

  def create_api_key
    api_keys.create
  end

  def api_key
    api_keys.first.try(:access_token)
  end

  def self.create_from_auth_hash(hash)
    create!(AuthHash.new(hash).user_info)
  end

  def assign_from_auth_hash(hash)
    update_attributes(AuthHash.new(hash).user_info)
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
    r = github_client.repos

    current_repo_ids = []
    r.each do |repo|
      github_repo = GithubRepository.find_by_full_name(repo.full_name)

      github_repo = GithubRepository.create_from_github(repo.full_name, token) if github_repo.nil?
      current_repo_ids << github_repo.id unless github_repo.nil?

      rp = repository_permissions.find_or_initialize_by(github_repository: github_repo)
      rp.admin = repo.permissions.admin
      rp.push = repo.permissions.push
      rp.pull = repo.permissions.pull
      rp.save
    end

    # delete missing permissions
    existing_repo_ids = repository_permissions.pluck(:github_repository_id)
    remove_ids = existing_repo_ids - current_repo_ids
    repository_permissions.where(github_repository_id: remove_ids).delete_all if remove_ids.any?
  rescue Octokit::Unauthorized, Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway => e
    nil
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
    repository_subscriptions.find_or_create_by(github_repository_id: github_repository.id, hook_id: hook.id)
  end

  def unsubscribe_from_repo(github_repository)
    sub = subscribed_to_repo?(github_repository)
    github_repository.remove_hook(sub.hook_id, token)
    sub.destroy
  end

  def subscribed_to?(project)
    subscriptions.find_by_project_id(project.id)
  end

  def subscribed_to_repo?(github_repository)
    repository_subscriptions.find_by_github_repository_id(github_repository.id)
  end

  def can_read?(github_repository)
    repository_permissions.where(github_repository: github_repository).where(pull: true).any?
  end
end
