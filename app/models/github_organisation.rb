class GithubOrganisation < ApplicationRecord
  include Profile

  API_FIELDS = [:name, :login, :blog, :email, :location, :bio]

  has_many :repositories
  has_many :source_repositories, -> { where fork: false }, anonymous_class: Repository
  has_many :open_source_repositories, -> { where fork: false, private: false }, anonymous_class: Repository
  has_many :dependencies, through: :open_source_repositories
  has_many :favourite_projects, -> { group('projects.id').order("COUNT(projects.id) DESC") }, through: :dependencies, source: :project
  has_many :all_dependent_repos, -> { group('repositories.id') }, through: :favourite_projects, source: :repository
  has_many :contributors, -> { group('github_users.id').order("sum(contributions.count) DESC") }, through: :open_source_repositories, source: :contributors
  has_many :projects, through: :open_source_repositories

  validates :login, uniqueness: true, if: lambda { self.login_changed? }
  validates :github_id, uniqueness: true, if: lambda { self.github_id_changed? }

  after_commit :async_sync, on: :create

  scope :most_repos, -> { joins(:open_source_repositories).select('github_organisations.*, count(repositories.id) AS repo_count').group('github_organisations.id').order('repo_count DESC') }
  scope :most_stars, -> { joins(:open_source_repositories).select('github_organisations.*, sum(repositories.stargazers_count) AS star_count, count(repositories.id) AS repo_count').group('github_organisations.id').order('star_count DESC') }
  scope :newest, -> { joins(:open_source_repositories).select('github_organisations.*, count(repositories.id) AS repo_count').group('github_organisations.id').order('created_at DESC').having('count(repositories.id) > 0') }
  scope :visible, -> { where(hidden: false) }
  scope :with_login, -> { where("github_organisations.login <> ''") }

  def meta_tags
    {
      title: "#{self} on GitHub",
      description: "GitHub repositories created by #{self}",
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

  def github_client
    AuthToken.client
  end

  def self.create_from_github(login_or_id)
    begin
      r = AuthToken.client.org(login_or_id).to_hash
      return false if r.blank?

      org = nil
      org_by_id = GithubOrganisation.find_by_github_id(r[:id])
      org_by_login = GithubOrganisation.where("lower(login) = ?", r[:login].downcase).first

      if org_by_id # its fine
        if org_by_id.login.try(:downcase) == r[:login].downcase
          org = org_by_id
        else
          if org_by_login && !org_by_login.download_from_github
            org_by_login.destroy
          end
          org_by_id.login = r[:login]
          org_by_id.save!
          org = org_by_id
        end
      elsif org_by_login # conflict
        if org_by_login.download_from_github_by_login
          org = org_by_login if org_by_login.github_id == r[:id]
        end
        org_by_login.destroy if org.nil?
      end
      if org.nil?
        org = GithubOrganisation.create!(github_id: r[:id], login: r[:login])
      end

      org.assign_attributes r.slice(*GithubOrganisation::API_FIELDS)
      org.save
      org
    rescue *Repository::IGNORABLE_GITHUB_EXCEPTIONS
      false
    end
  end

  def async_sync
    GithubUpdateOrgWorker.perform_async(self.login)
  end

  def sync
    download_from_github
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
    update_attributes(github_client.org(github_id).to_hash.slice(:login, :name, :email, :blog, :location, :bio))
  rescue *Repository::IGNORABLE_GITHUB_EXCEPTIONS
    nil
  end

  def download_repos
    github_client.org_repos(login).each do |repo|
      GithubCreateWorker.perform_async(repo.full_name)
    end
  rescue *Repository::IGNORABLE_GITHUB_EXCEPTIONS
    nil
  end
end
