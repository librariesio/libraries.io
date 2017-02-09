class Repository < ApplicationRecord
  include RepoSearch
  include Status
  include RepoUrls
  include RepoManifests
  include RepoTags
  include RepositorySourceRank

  include GithubRepository
  include GitlabRepository
  include BitbucketRepository

  IGNORABLE_GITHUB_EXCEPTIONS = [Octokit::Unauthorized, Octokit::InvalidRepository, Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Conflict, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway, Octokit::ClientError]

  STATUSES = ['Active', 'Deprecated', 'Unmaintained', 'Help Wanted', 'Removed']

  API_FIELDS = [:full_name, :description, :fork, :created_at, :updated_at, :pushed_at, :homepage,
   :size, :stargazers_count, :language, :has_issues, :has_wiki, :has_pages,
   :forks_count, :mirror_url, :open_issues_count, :default_branch,
   :subscribers_count, :private, :logo_url, :pull_requests_enabled, :scm, ]

  has_many :projects
  has_many :contributions, dependent: :delete_all
  has_many :contributors, through: :contributions, source: :github_user
  has_many :tags, dependent: :delete_all
  has_many :published_tags, -> { published }, anonymous_class: Tag
  has_many :manifests, dependent: :destroy
  has_many :dependencies, through: :manifests, source: :repository_dependencies
  has_many :dependency_projects, -> { group('projects.id').order("COUNT(projects.id) DESC") }, through: :dependencies, source: :project
  has_many :dependency_repos, -> { group('repositories.id') }, through: :dependency_projects, source: :repository

  has_many :repository_subscriptions, dependent: :delete_all
  has_many :web_hooks, dependent: :delete_all
  has_many :issues, dependent: :delete_all
  has_one :readme, dependent: :delete
  belongs_to :github_organisation
  belongs_to :github_user, primary_key: :github_id, foreign_key: :owner_id
  belongs_to :source, primary_key: :full_name, foreign_key: :source_name, anonymous_class: Repository
  has_many :forked_repositories, primary_key: :full_name, foreign_key: :source_name, anonymous_class: Repository

  validates :full_name, uniqueness: true, if: lambda { self.full_name_changed? }
  validates :uuid, uniqueness: true, if: lambda { self.uuid_changed? }

  before_save  :normalize_license_and_language
  after_commit :update_all_info_async, on: :create
  after_commit :save_projects, on: :update
  after_commit :update_source_rank_async

  scope :without_readme, -> { where("repositories.id NOT IN (SELECT repository_id FROM readmes)") }
  scope :with_projects, -> { joins(:projects) }
  scope :without_projects, -> { includes(:projects).where(projects: { repository_id: nil }) }
  scope :without_subscriptons, -> { includes(:repository_subscriptions).where(repository_subscriptions: { repository_id: nil }) }
  scope :with_tags, -> { joins(:tags) }
  scope :without_tags, -> { includes(:tags).where(tags: { repository_id: nil }) }

  scope :host, lambda{ |host_type| where('lower(repositories.host_type) = ?', host_type.try(:downcase)) }

  scope :fork, -> { where(fork: true) }
  scope :source, -> { where(fork: false) }

  scope :open_source, -> { where(private: false) }
  scope :from_org, lambda{ |org_id|  where(github_organisation_id: org_id) }

  scope :with_manifests, -> { joins(:manifests) }
  scope :without_manifests, -> { includes(:manifests).where(manifests: {repository_id: nil}) }

  scope :with_description, -> { where("repositories.description <> ''") }
  scope :with_license, -> { where("repositories.license <> ''") }
  scope :without_license, -> {where("repositories.license IS ? OR repositories.license = ''", nil)}

  scope :pushed, -> { where.not(pushed_at: nil) }
  scope :good_quality, -> { maintained.open_source.pushed }
  scope :with_stars, -> { where('repositories.stargazers_count > 0') }
  scope :interesting, -> { with_stars.order('repositories.stargazers_count DESC, repositories.pushed_at DESC') }
  scope :uninteresting, -> { without_readme.without_manifests.without_license.where('repositories.stargazers_count = 0').where('repositories.forks_count = 0') }

  scope :recently_created, -> { where('created_at > ?', 7.days.ago)}
  scope :hacker_news, -> { order("((stargazers_count-1)/POW((EXTRACT(EPOCH FROM current_timestamp-created_at)/3600)+2,1.8)) DESC") }
  scope :trending, -> { good_quality.recently_created.with_stars }

  scope :maintained, -> { where('repositories."status" not in (?) OR repositories."status" IS NULL', ["Deprecated", "Removed", "Unmaintained"])}
  scope :deprecated, -> { where('repositories."status" = ?', "Deprecated")}
  scope :not_removed, -> { where('repositories."status" != ? OR repositories."status" IS NULL', "Removed")}
  scope :removed, -> { where('repositories."status" = ?', "Removed")}
  scope :unmaintained, -> { where('repositories."status" = ?', "Unmaintained")}

  scope :indexable, -> { open_source.not_removed.includes(:projects, :readme) }

  def self.language(language)
    where('lower(repositories.language) = ?', language.try(:downcase))
  end

  def self.formatted_host(host_type)
    case host_type.try(:downcase)
    when 'github'
      'GitHub'
    when 'gitlab'
      'GitLab'
    when 'bitbucket'
      'Bitbucket'
    end
  end

  def formatted_host
    Repository.formatted_host(host_type)
  end

  def meta_tags
    {
      title: "#{full_name} on #{formatted_host}",
      description: description_with_language,
      image: avatar_url(200)
    }
  end

  def description_with_language
    language_text = [language, "repository"].compact.join(' ').with_indefinite_article
    [description, "#{language_text} on #{formatted_host}"].compact.join(' - ')
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
    return nil unless host_type == 'GitHub'
    github_organisation_id.present? ? github_organisation : github_user
  end

  def download_owner
    case host_type
    when 'GitHub'
      download_github_owner
    when 'GitLab'

    when 'Bitbucket'

    end
  end

  def to_s
    full_name
  end

  def to_param
    {
      host_type: host_type.downcase,
      owner: owner_name,
      name: project_name
    }
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
    case host_type
    when 'GitHub'
      avatar = github_avatar_url(size)
    when 'GitLab'
      avatar = gitlab_avatar_url(size)
    when 'Bitbucket'
      avatar = bitbucket_avatar_url(size)
    end
    return fallback_avatar_url(size) if avatar.blank?
    avatar
  end

  def fallback_avatar_url(size = 60)
    hash = Digest::MD5.hexdigest("#{host_type}-#{full_name}")
    "https://www.gravatar.com/avatar/#{hash}?s=#{size}&f=y&d=retro"
  end

  def load_dependencies_tree(date = nil)
    RepositoryTreeResolver.new(self, date).load_dependencies_tree
  end

  def id_or_name
    uuid || full_name
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

  def update_all_info_async(token = nil)
    RepositoryDownloadWorker.perform_async(self.id, token)
  end

  def update_from_repository(token = nil)
    case host_type
    when 'GitHub'
      update_from_github(token)
    when 'GitLab'

    when 'Bitbucket'

    end
  end

  def update_all_info(token = nil)
    token ||= AuthToken.token
    previous_pushed_at = self.pushed_at
    update_from_repository(token)
    download_owner
    download_fork_source(token)
    if (previous_pushed_at.nil? && self.pushed_at) || (self.pushed_at && previous_pushed_at < self.pushed_at)
      download_readme(token)
      download_tags(token)
      download_contributions(token)
      download_manifests(token)
      # download_issues(token)
    end
    save_projects
    update_attributes(last_synced_at: Time.now)
  end

  def download_fork_source(token = nil)
    return true unless self.fork? && self.source.nil?
    Repository.create_from_github(source_name, token)
  end

  def download_forks_async(token = nil)
    GithubDownloadForkWorker.perform_async(self.id, token)
  end

  def download_forks(token = nil)
    return true if fork?
    return true unless forks_count && forks_count > 0 && forks_count < 100
    return true if forks_count == forked_repositories.count
    AuthToken.new_client(token).forks(full_name).each do |fork|
      Repository.create_from_hash(fork)
    end
  end

  def download_contributions(token = nil)
    gh_contributions = github_client(token).contributors(full_name)
    return if gh_contributions.empty?
    existing_contributions = contributions.includes(:github_user).to_a
    platform = projects.first.try(:platform)
    gh_contributions.each do |c|
      next unless c['id']
      cont = existing_contributions.find{|cnt| cnt.github_user.try(:github_id) == c.id }
      unless cont
        user = GithubUser.create_from_github(c)
        cont = contributions.find_or_create_by(github_user: user)
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
      Issue.create_from_hash(self, issue)
    end
  rescue *IGNORABLE_GITHUB_EXCEPTIONS
    nil
  end

  def self.create_from_host(host_type, full_name, token = nil)
    case host_type
    when 'GitHub'
      create_from_github(full_name, token)
    when 'GitLab'
      create_from_gitlab(full_name, token)
    when 'Bitbucket'
      raise 'Not Implemented yet'
    end
  end

  def self.create_from_hash(repo_hash)
    repo_hash = repo_hash.to_hash.with_indifferent_access
    ActiveRecord::Base.transaction do
      g = Repository.find_by(uuid: repo_hash[:id])
      g = Repository.find_by('lower(full_name) = ?', repo_hash[:full_name].downcase) if g.nil?
      g = Repository.new(uuid: repo_hash[:id], full_name: repo_hash[:full_name]) if g.nil?
      g.owner_id = repo_hash[:owner][:id]
      g.host_type = repo_hash[:host_type] || 'GitHub'
      g.full_name = repo_hash[:full_name] if g.full_name.downcase != repo_hash[:full_name].downcase
      g.uuid = repo_hash[:id] if g.uuid.nil?
      g.license = repo_hash[:license][:key] if repo_hash[:license]
      g.source_name = repo_hash[:parent][:full_name] if repo_hash[:fork] && repo_hash[:parent]
      g.assign_attributes repo_hash.slice(*Repository::API_FIELDS)

      if g.changed?
        return g.save ? g : nil
      else
        return g
      end
    end
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  def self.check_status(repo_full_name, removed = false)
    response = Typhoeus.head("https://github.com/#{repo_full_name}")

    if response.response_code == 404
      repo = Repository.includes(:projects).find_by_full_name(repo_full_name)
      if repo
        status = removed ? nil : 'Removed'
        repo.update_attribute(:status, status) if !repo.private?
        repo.projects.each do |project|
          next unless ['bower', 'go', 'elm', 'alcatraz', 'julia', 'nimble'].include?(project.platform.downcase)
          project.update_attribute(:status, status)
        end
      end
    end
  end

  def self.update_from_hook(uuid, sender_id)
    repository = Repository.find_by_uuid(uuid)
    user = Identity.where('provider ILIKE ?', 'github%').where(uid: sender_id).first.try(:user)
    if user.present? && repository.present?
      repository.download_manifests(user.token)
      repository.update_all_info_async(user.token)
    end
  end

  def self.update_from_star(repo_name, token = nil)
    token ||= AuthToken.token

    repository = Repository.find_by_full_name(repo_name)
    if repository
      repository.increment!(:stargazers_count)
    else
      Repository.create_from_github(repo_name, token)
    end
  end

  def self.update_from_tag(repo_name, token = nil)
    token ||= AuthToken.token

    repository = Repository.find_by_full_name(repo_name)
    if repository
      repository.download_tags(token)
    else
      Repository.create_from_github(repo_name, token)
    end
  end

  def self.update_from_name(repo_name, token = nil)
    token ||= AuthToken.token
    repository = Repository.find_by_full_name(repo_name)
    if repository
      repository.update_from_repository(token)
    else
      Repository.create_from_github(repo_name, token)
    end
  end
end
