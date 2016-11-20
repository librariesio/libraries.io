class GithubUser < ApplicationRecord
  include Profile

  has_many :github_contributions, dependent: :delete_all
  has_many :github_repositories, primary_key: :github_id, foreign_key: :owner_id
  has_many :source_github_repositories, -> { where fork: false }, anonymous_class: GithubRepository, primary_key: :github_id, foreign_key: :owner_id
  has_many :open_source_github_repositories, -> { where fork: false, private: false }, anonymous_class: GithubRepository, primary_key: :github_id, foreign_key: :owner_id
  has_many :dependencies, through: :open_source_github_repositories
  has_many :favourite_projects, -> { group('projects.id').order("COUNT(projects.id) DESC") }, through: :dependencies, source: :project
  has_many :contributed_repositories, -> { GithubRepository.source.open_source }, through: :github_contributions, source: :github_repository
  has_many :contributors, -> { group('github_users.id').order("sum(github_contributions.count) DESC") }, through: :open_source_github_repositories, source: :contributors
  has_many :fellow_contributors, -> (object){ where.not(id: object.id).group('github_users.id').order("COUNT(github_users.id) DESC") }, through: :contributed_repositories, source: :contributors
  has_many :projects, through: :open_source_github_repositories

  has_many :github_issues, primary_key: :github_id

  validates :login, uniqueness: true, if: lambda { self.login_changed? }
  validates :github_id, uniqueness: true, if: lambda { self.github_id_changed? }
  validates :github_id, presence: true

  after_commit :async_sync, on: :create

  scope :visible, -> { where(hidden: false) }

  def meta_tags
    {
      title: "#{self} on GitHub",
      description: "GitHub repositories created and contributed to by #{self}",
      image: avatar_url(200)
    }
  end

  def open_source_contributions
    github_contributions.joins(:github_repository).where("github_repositories.fork = ? AND github_repositories.private = ?", false, false)
  end

  def org?
    false
  end

  def description
    nil
  end

  def github_client
    AuthToken.client
  end

  def async_sync
    GithubUpdateUserWorker.perform_async(self.login)
  end

  def sync
    download_from_github
    download_orgs
    download_repos
    update_attributes(last_synced_at: Time.now)
  end

  def download_from_github
    download_from_github_by(github_id)
  end

  def download_from_github_by_login
    download_from_github_by(login)
  end

  def download_from_github_by(id_or_login)
    update_attributes(github_client.user(id_or_login).to_hash.slice(:login, :name, :company, :blog, :location, :email, :bio, :followers, :following))
  rescue *GithubRepository::IGNORABLE_GITHUB_EXCEPTIONS
    nil
  end

  def download_orgs
    github_client.orgs(login).each do |org|
      GithubCreateOrgWorker.perform_async(org.login)
    end
    true
  rescue *GithubRepository::IGNORABLE_GITHUB_EXCEPTIONS
    nil
  end

  def download_repos
    AuthToken.client.search_repos("user:#{login}").items.each do |repo|
      GithubRepository.create_from_hash repo.to_hash
    end

    true
  rescue *GithubRepository::IGNORABLE_GITHUB_EXCEPTIONS
    nil
  end

  def self.create_from_github(github_user)
    user = nil
    user_by_id = GithubUser.find_by_github_id(github_user.id)
    user_by_login = GithubUser.where("lower(login) = ?", github_user.login.downcase).first
    if user_by_id # its fine
      if user_by_id.login.downcase == github_user.login.downcase && user_by_id.user_type == github_user.type
        user = user_by_id
      else
        unless user_by_login.download_from_github_by_login
          user_by_login.destroy
        end
        user_by_id.login = github_user.login
        user_by_id.user_type = github_user.type
        user_by_id.save!
        user = user_by_id
      end
    elsif user_by_login # conflict
      if user_by_login.download_from_github_by_login
        user = user_by_login if user_by_login.github_id == github_user.id
      end
      user_by_login.destroy if user.nil?
    end
    if user.nil?
      user = GithubUser.create!(github_id: github_user.id, login: github_user.login, user_type: github_user.type)
    end
    user
  end
end
