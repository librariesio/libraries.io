class GithubRepository < ApplicationRecord
  include RepoSearch
  include Status
  include RepoUrls
  include RepoManifests
  include RepoTags

  IGNORABLE_GITHUB_EXCEPTIONS = [Octokit::Unauthorized, Octokit::InvalidRepository, Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Conflict, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway, Octokit::ClientError]

  STATUSES = ['Active', 'Deprecated', 'Unmaintained', 'Help Wanted', 'Removed']

  API_FIELDS = [:full_name, :description, :fork, :created_at, :updated_at, :pushed_at, :homepage,
   :size, :stargazers_count, :language, :has_issues, :has_wiki, :has_pages,
   :forks_count, :mirror_url, :open_issues_count, :default_branch,
   :subscribers_count, :private]

  has_many :projects
  has_many :github_contributions, dependent: :delete_all
  has_many :contributors, through: :github_contributions, source: :github_user
  has_many :github_tags, dependent: :delete_all
  has_many :published_github_tags, -> { published }, anonymous_class: GithubTag
  has_many :manifests, dependent: :destroy
  has_many :dependencies, through: :manifests, source: :repository_dependencies
  has_many :dependency_projects, -> { group('projects.id').order("COUNT(projects.id) DESC") }, through: :dependencies, source: :project
  has_many :dependency_repos, -> { group('github_repositories.id') }, through: :dependency_projects, source: :github_repository

  has_many :repository_subscriptions, dependent: :delete_all
  has_many :web_hooks, dependent: :delete_all
  has_many :github_issues, dependent: :delete_all
  has_one :readme, dependent: :delete
  belongs_to :github_organisation
  belongs_to :github_user, primary_key: :github_id, foreign_key: :owner_id
  belongs_to :source, primary_key: :full_name, foreign_key: :source_name, anonymous_class: GithubRepository
  has_many :forked_repositories, primary_key: :full_name, foreign_key: :source_name, anonymous_class: GithubRepository

  validates :full_name, uniqueness: true, if: lambda { self.full_name_changed? }
  validates :github_id, uniqueness: true, if: lambda { self.github_id_changed? }

  before_save  :normalize_license_and_language
  after_commit :update_all_info_async, on: :create
  after_commit :save_projects, on: :update

  scope :without_readme, -> { where("github_repositories.id NOT IN (SELECT github_repository_id FROM readmes)") }
  scope :with_projects, -> { joins(:projects) }
  scope :without_projects, -> { includes(:projects).where(projects: { github_repository_id: nil }) }
  scope :without_subscriptons, -> { includes(:repository_subscriptions).where(repository_subscriptions: { github_repository_id: nil }) }
  scope :with_tags, -> { joins(:github_tags) }
  scope :without_tags, -> { includes(:github_tags).where(github_tags: { github_repository_id: nil }) }

  scope :fork, -> { where(fork: true) }
  scope :source, -> { where(fork: false) }

  scope :open_source, -> { where(private: false) }
  scope :from_org, lambda{ |org_id|  where(github_organisation_id: org_id) }

  scope :with_manifests, -> { joins(:manifests) }
  scope :without_manifests, -> { includes(:manifests).where(manifests: {github_repository_id: nil}) }

  scope :with_description, -> { where("github_repositories.description <> ''") }
  scope :with_license, -> { where("github_repositories.license <> ''") }
  scope :without_license, -> {where("github_repositories.license IS ? OR github_repositories.license = ''", nil)}

  scope :pushed, -> { where.not(pushed_at: nil) }
  scope :good_quality, -> { maintained.open_source.pushed }
  scope :with_stars, -> { where('github_repositories.stargazers_count > 0') }
  scope :interesting, -> { with_stars.order('github_repositories.stargazers_count DESC, github_repositories.pushed_at DESC') }
  scope :uninteresting, -> { without_readme.without_manifests.without_license.where('github_repositories.stargazers_count = 0').where('github_repositories.forks_count = 0') }

  scope :recently_created, -> { where('created_at > ?', 7.days.ago)}
  scope :hacker_news, -> { order("((stargazers_count-1)/POW((EXTRACT(EPOCH FROM current_timestamp-created_at)/3600)+2,1.8)) DESC") }
  scope :trending, -> { good_quality.recently_created.with_stars }

  scope :maintained, -> { where('github_repositories."status" not in (?) OR github_repositories."status" IS NULL', ["Deprecated", "Removed", "Unmaintained"])}
  scope :deprecated, -> { where('github_repositories."status" = ?', "Deprecated")}
  scope :not_removed, -> { where('github_repositories."status" != ? OR github_repositories."status" IS NULL', "Removed")}
  scope :removed, -> { where('github_repositories."status" = ?', "Removed")}
  scope :unmaintained, -> { where('github_repositories."status" = ?', "Unmaintained")}

  scope :indexable, -> { open_source.not_removed.includes(:projects, :readme) }

  def self.language(language)
    where('lower(github_repositories.language) = ?', language.try(:downcase))
  end

  def meta_tags
    {
      title: "#{full_name} on GitHub",
      description: description_with_language,
      image: avatar_url(200)
    }
  end

  def description_with_language
    language_text = [language, "repository"].compact.join(' ').with_indefinite_article
    [description, "#{language_text} on GitHub"].compact.join(' - ')
  end

  def normalize_license_and_language
    self.language = 'Haxe' if self.language == 'HaXe' # 😐
    return if license.blank?
    if license.downcase == 'other'
      self.license = 'Other'
    else
      l = Spdx.find(license).try(:id)
      l = 'Other' if l.blank?
      self.license = l
    end
  end

  def deprecate!
    update_attribute(:status, 'Deprecated')
    projects.each do |project|
      project.update_attribute(:status, 'Deprecated')
    end
  end

  def unmaintain!
    update_attribute(:status, 'Unmaintained')
    projects.each do |project|
      project.update_attribute(:status, 'Unmaintained')
    end
  end

  def save_projects
    projects.find_each(&:forced_save)
  end

  def repository_dependencies
    manifests.latest.includes({repository_dependencies: {project: :versions}}).map(&:repository_dependencies).flatten.uniq
  end

  def owner
    github_organisation_id.present? ? github_organisation : github_user
  end

  def download_owner
    o = github_client.user(owner_name)
    if o.type == "Organization"
      go = GithubOrganisation.create_from_github(owner_id.to_i)
      if go
        self.github_organisation_id = go.id
        save
      end
    else
      GithubUser.create_from_github(o)
    end
  rescue *IGNORABLE_GITHUB_EXCEPTIONS
    nil
  end

  def to_s
    full_name
  end

  def to_param
    full_name
  end

  def owner_name
    full_name.split('/')[0]
  end

  def project_name
    full_name.split('/')[1]
  end

  def color
    Languages::Language[language].try(:color)
  end

  def stars
    stargazers_count || 0
  end

  def forks
    forks_count || 0
  end

  def avatar_url(size = 60)
    "https://avatars.githubusercontent.com/u/#{owner_id}?size=#{size}"
  end

  def github_client(token = nil)
    AuthToken.fallback_client(token)
  end

  def id_or_name
    github_id || full_name
  end

  def download_readme(token = nil)
    contents = {html_body: github_client(token).readme(full_name, accept: 'application/vnd.github.V3.html')}
    if readme.nil?
      create_readme(contents)
    else
      readme.update_attributes(contents)
    end
  rescue *IGNORABLE_GITHUB_EXCEPTIONS
    nil
  end

  def update_from_github(token = nil)
    begin
      r = github_client(token).repo(id_or_name, accept: 'application/vnd.github.drax-preview+json').to_hash
      return unless r.present?
      self.github_id = r[:id] unless self.github_id == r[:id]
       if self.full_name.downcase != r[:full_name].downcase
         clash = GithubRepository.where('lower(full_name) = ?', r[:full_name].downcase).first
         if clash && !clash.update_from_github(token)
           clash.destroy
         end
         self.full_name = r[:full_name]
       end
      self.owner_id = r[:owner][:id]
      self.license = Project.format_license(r[:license][:key]) if r[:license]
      self.source_name = r[:parent][:full_name] if r[:fork]
      assign_attributes r.slice(*API_FIELDS)
      save! if self.changed?
    rescue Octokit::NotFound
      update_attribute(:status, 'Removed') if !self.private?
    rescue *IGNORABLE_GITHUB_EXCEPTIONS
      nil
    end
  end

  def update_all_info_async(token = nil)
    GithubDownloadWorker.perform_async(self.id, token)
  end

  def update_all_info(token = nil)
    previous_pushed_at = self.pushed_at
    update_from_github(token)
    if (previous_pushed_at.nil? && self.pushed_at) || (self.pushed_at && previous_pushed_at < self.pushed_at)
      download_readme(token)
      download_tags(token)
      download_github_contributions(token)
      download_manifests(token)
      download_owner
      download_fork_source(token)
    end
    # download_issues(token)
    save_projects
    update_attributes(last_synced_at: Time.now)
  end

  def download_fork_source(token = nil)
    return true unless self.fork? && self.source.nil?
    GithubRepository.create_from_github(source_name, token)
  end

  def download_forks_async(token = nil)
    GithubDownloadForkWorker.perform_async(self.id, token)
  end

  def download_forks(token = nil)
    return true if fork?
    return true unless forks_count && forks_count > 0 && forks_count < 100
    return true if forks_count == forked_repositories.count
    AuthToken.new_client(token).forks(full_name).each do |fork|
      GithubRepository.create_from_hash(fork)
    end
  end

  def download_github_contributions(token = nil)
    contributions = github_client(token).contributors(full_name)
    return if contributions.empty?
    existing_github_contributions = github_contributions.includes(:github_user).to_a
    platform = projects.first.try(:platform)
    contributions.each do |c|
      next unless c['id']
      cont = existing_github_contributions.find{|cnt| cnt.github_user.try(:github_id) == c.id }
      unless cont
        user = GithubUser.create_from_github(c)
        cont = github_contributions.find_or_create_by(github_user: user)
      end

      cont.count = c.contributions
      cont.platform = platform
      cont.save! if cont.changed?
    end
    true
  rescue *IGNORABLE_GITHUB_EXCEPTIONS
    nil
  end

  def create_webhook(token)
    github_client(token).create_hook(
      full_name,
      'web',
      {
        :url => 'https://libraries.io/hooks/github',
        :content_type => 'json'
      },
      {
        :events => ['push', 'pull_request'],
        :active => true
      }
    )
  rescue Octokit::UnprocessableEntity
    nil
  end

  def download_issues(token = nil)
    github_client = AuthToken.new_client(token)
    issues = github_client.issues(full_name, state: 'all')
    issues.each do |issue|
      GithubIssue.create_from_hash(self, issue)
    end
  rescue *IGNORABLE_GITHUB_EXCEPTIONS
    nil
  end

  def self.create_from_github(full_name, token = nil)
    github_client = AuthToken.new_client(token)
    repo_hash = github_client.repo(full_name, accept: 'application/vnd.github.drax-preview+json').to_hash
    return false if repo_hash.nil? || repo_hash.empty?
    create_from_hash(repo_hash)
  rescue *IGNORABLE_GITHUB_EXCEPTIONS
    nil
  end

  def self.create_from_hash(repo_hash)
    repo_hash = repo_hash.to_hash
    ActiveRecord::Base.transaction do
      g = GithubRepository.find_by(github_id: repo_hash[:id])
      g = GithubRepository.find_by('lower(full_name) = ?', repo_hash[:full_name].downcase) if g.nil?
      g = GithubRepository.new(github_id: repo_hash[:id], full_name: repo_hash[:full_name]) if g.nil?
      g.owner_id = repo_hash[:owner][:id]
      g.full_name = repo_hash[:full_name] if g.full_name.downcase != repo_hash[:full_name].downcase
      g.github_id = repo_hash[:id] if g.github_id.nil?
      g.license = repo_hash[:license][:key] if repo_hash[:license]
      g.source_name = repo_hash[:parent][:full_name] if repo_hash[:fork] && repo_hash[:parent]
      g.assign_attributes repo_hash.slice(*GithubRepository::API_FIELDS)

      if g.changed?
        return g.save ? g : nil
      else
        return g
      end
    end
  rescue ActiveRecord::RecordNotUnique
    nil
  end
end
