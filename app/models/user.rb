class User < ActiveRecord::Base
  has_many :subscriptions
  has_many :repository_subscriptions
  has_many :api_keys
  has_many :github_repositories, primary_key: :uid, foreign_key: :owner_id
  has_many :source_github_repositories, -> { where fork: false }, class: GithubRepository, primary_key: :github_id, foreign_key: :owner_id
  has_many :dependencies, through: :source_github_repositories
  has_many :favourite_projects, -> { group('projects.id').order("COUNT(projects.id) DESC") }, through: :dependencies, source: :project

  def admin?
    ['andrew', 'barisbalic', 'malditogeek', 'olizilla', 'thattommyhall', 'zachinglis'].include?(nickname)
  end

  def api_key
    api_keys.first.access_token
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
    public_repo_token.presence || read_attribute(:token)
  end

  def github_client
    AuthToken.new_client(token)
  end

  def repos
    github_client.repos.select{|r|r[:permissions][:admin]}
  rescue
    []
  end

  def download_repos
    repos.each do |repo|
      GithubCreateWorker.perform_async(repo.full_name, token)
    end
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
end
