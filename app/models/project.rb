class Project < ApplicationRecord
  include ProjectSearch
  include SourceRank
  include Status
  include Releases

  include GithubProject
  include GitlabProject
  include BitbucketProject

  HAS_DEPENDENCIES = false
  STATUSES = ['Active', 'Deprecated', 'Unmaintained', 'Help Wanted', 'Removed']
  API_FIELDS = [:name, :platform, :description, :language, :homepage,
                :repository_url, :normalized_licenses, :rank, :status,
                :latest_release_number, :latest_release_published_at]

  validates_presence_of :name, :platform
  validates_uniqueness_of :name, scope: :platform, case_sensitive: true

  has_many :versions
  has_many :dependencies, -> { group 'project_name' }, through: :versions
  has_many :contributions, through: :repository
  has_many :contributors, through: :contributions, source: :github_user
  has_many :tags, through: :repository
  has_many :dependents, class_name: 'Dependency'
  has_many :dependent_versions, through: :dependents, source: :version, class_name: 'Version'
  has_many :dependent_projects, -> { group('projects.id') }, through: :dependent_versions, source: :project, class_name: 'Project'
  has_many :repository_dependencies
  has_many :dependent_manifests, through: :repository_dependencies, source: :manifest
  has_many :dependent_repositories, -> { group('repositories.id').order('repositories.stargazers_count DESC') }, through: :dependent_manifests, source: :repository
  has_many :subscriptions
  has_many :project_suggestions, dependent: :delete_all
  belongs_to :repository
  has_one :readme, through: :repository

  scope :platform, ->(platform) { where('lower(platform) = ?', platform.try(:downcase)) }
  scope :with_homepage, -> { where("homepage <> ''") }
  scope :with_repository_url, -> { where("repository_url <> ''") }
  scope :without_repository_url, -> { where("repository_url IS ? OR repository_url = ''", nil) }
  scope :with_repo, -> { joins(:repository).where('repositories.id IS NOT NULL') }
  scope :without_repo, -> { where(repository_id: nil) }
  scope :with_description, -> { where("projects.description <> ''") }

  scope :with_license, -> { where("licenses <> ''") }
  scope :without_license, -> { where("licenses IS ? OR licenses = ''", nil) }
  scope :unlicensed, -> { maintained.without_license.with_repo.where("repositories.license IS ? OR repositories.license = ''", nil) }

  scope :with_versions, -> { where('versions_count > 0') }
  scope :without_versions, -> { where('versions_count < 1') }
  scope :few_versions, -> { where('versions_count < 2') }
  scope :many_versions, -> { where('versions_count > 2') }

  scope :with_dependents, -> { where('dependents_count > 0') }
  scope :with_dependent_repos, -> { where('dependent_repos_count > 0') }

  scope :with_github_url, -> { where('repository_url ILIKE ?', '%github.com%') }
  scope :with_gitlab_url, -> { where('repository_url ILIKE ?', '%gitlab.com%') }
  scope :with_bitbucket_url, -> { where('repository_url ILIKE ?', '%bitbucket.org%') }
  scope :with_launchpad_url, -> { where('repository_url ILIKE ?', '%launchpad.net%') }
  scope :with_sourceforge_url, -> { where('repository_url ILIKE ?', '%sourceforge.net%') }

  scope :most_watched, -> { joins(:subscriptions).group('projects.id').order("COUNT(subscriptions.id) DESC") }
  scope :most_dependents, -> { with_dependents.order('dependents_count DESC') }
  scope :most_dependent_repos, -> { with_dependent_repos.order('dependent_repos_count DESC') }

  scope :maintained, -> { where('projects."status" not in (?) OR projects."status" IS NULL', ["Deprecated", "Removed", "Unmaintained"])}
  scope :deprecated, -> { where('projects."status" = ?', "Deprecated")}
  scope :not_removed, -> { where('projects."status" != ? OR projects."status" IS NULL', "Removed")}
  scope :removed, -> { where('projects."status" = ?', "Removed")}
  scope :unmaintained, -> { where('projects."status" = ?', "Unmaintained")}

  scope :indexable, -> { not_removed.includes(:repository) }

  scope :unsung_heroes, -> { maintained
                             .with_dependent_repos
                             .with_repo
                             .where('repositories.stargazers_count < 100')
                             .where('projects.dependent_repos_count > 1000') }

  scope :bus_factor, -> { maintained
                          .joins(:repository)
                          .where('repositories.contributions_count < 6')
                          .where('repositories.contributions_count > 0')
                          .where('repositories.stargazers_count > 0')}

  scope :hacker_news, -> { with_repo.where('repositories.stargazers_count > 0').order("((repositories.stargazers_count-1)/POW((EXTRACT(EPOCH FROM current_timestamp-repositories.created_at)/3600)+2,1.8)) DESC") }
  scope :recently_created, -> { with_repo.where('repositories.created_at > ?', 1.month.ago)}

  after_commit :update_repository_async, on: :create
  after_commit :set_dependents_count
  after_commit :update_source_rank_async
  before_save  :update_details
  before_destroy :destroy_versions

  def self.total
    Rails.cache.fetch 'projects:total', :expires_in => 1.day, race_condition_ttl: 2.minutes do
      self.all.count
    end
  end

  def to_param
    { name: name, platform: platform.downcase }
  end

  def to_s
    name
  end

  def manual_sync
    async_sync
    update_repository_async
    self.last_synced_at = Time.zone.now
    forced_save
  end

  def forced_save
    self.updated_at = Time.zone.now
    save
  end

  def sync
    platform_class.update(name)
  end

  def async_sync
    PackageManagerDownloadWorker.perform_async(platform, name)
  end

  def recently_synced?
    last_synced_at && last_synced_at > 1.day.ago
  end

  def contributions_count
    repository.try(:contributions_count) || 0
  end

  def meta_tags
    {
      title: "#{name} on #{platform}",
      description: description,
    }
  end

  def follows_semver?
    if versions.all.length > 0
      versions.all?(&:follows_semver?)
    elsif tags.published.length > 0
      tags.published.all?(&:follows_semver?)
    end
  end

  def update_details
    normalize_licenses
    set_latest_release_published_at
    set_latest_release_number
    set_language
  end

  def keywords
    keywords_array
  end

  def package_manager_url(version = nil)
    platform_class.package_link(self, version)
  end

  def download_url(version = nil)
    platform_class.download_url(name, version)
  end

  def documentation_url(version = nil)
    platform_class.documentation_url(name, version)
  end

  def install_instructions(version = nil)
    platform_class.install_instructions(self, version)
  end

  def owner
    return nil unless repository && repository.host_type == 'GitHub'
    GithubUser.visible.find_by_login repository.owner_name
  end

  def platform_class
    "PackageManager::#{platform}".constantize
  end

  def platform_name
    platform_class.formatted_name
  end

  def color
    Languages::Language[language].try(:color) || platform_class.try(:color)
  end

  def mlt
    begin
      Project.where(id: mlt_ids).limit(5)
    rescue
      []
    end
  end

  def mlt_ids
    Rails.cache.fetch "projects:#{self.id}:mlt_ids", :expires_in => 1.week do
      results = Project.__elasticsearch__.client.mlt(id: self.id, index: 'projects', type: 'project', mlt_fields: 'keywords_array,platform,description,repository_url', min_term_freq: 1, min_doc_freq: 2)
      results['hits']['hits'].map{|h| h['_id']}
    end
  end

  def destroy_versions
    versions.find_each(&:destroy)
  end

  def stars
    repository.try(:stargazers_count) || 0
  end

  def forks
    repository.try(:forks_count) || 0
  end

  def set_language
    return unless repository
    self.language = repository.try(:language)
  end

  def repo_name
    repository.try(:full_name)
  end

  def description
    if platform == 'Go'
      repository.try(:description).presence || read_attribute(:description)
    else
      read_attribute(:description).presence || repository.try(:description)
    end
  end

  def homepage
    read_attribute(:homepage).presence || repository.try(:homepage)
  end

  def set_dependents_count
    return if destroyed?
    self.update_columns(dependents_count: dependents.joins(:version).pluck('DISTINCT versions.project_id').count,
                        dependent_repos_count: dependent_repositories.open_source.count.length)
  end

  def needs_suggestions?
    repository_url.blank? || normalized_licenses.blank?
  end

  def self.undownloaded_repos
    with_github_url.or(with_gitlab_url).or(with_bitbucket_url).without_repo
  end

  def self.license(license)
    where.contains(normalized_licenses: [license])
  end

  def self.keyword(keyword)
    where.contains(keywords_array: [keyword])
  end

  def self.keywords(keywords)
    where.overlap(keywords_array: keywords)
  end

  def self.language(language)
    where('lower(projects.language) = ?', language.try(:downcase))
  end

  def self.all_languages
    @all_languages ||= Languages::Language.all.map{|l| l.name.downcase}
  end

  def self.popular_languages(options = {})
    facets(options)[:languages].language.buckets
  end

  def self.popular_platforms(options = {})
    facets(options)[:platforms].platform.buckets.reject{ |t| ['biicode', 'jam'].include?(t['key'].downcase) }
  end

  def self.keywords_badlist
    ['bsd3', 'library']
  end

  def self.popular_keywords(options = {})
    facets(options)[:keywords].keywords_array.buckets.reject{ |t| all_languages.include?(t['key'].downcase) }.reject{|t| keywords_badlist.include?(t['key'].downcase) }
  end

  def self.popular_licenses(options = {})
    facets(options)[:licenses].normalized_licenses.buckets.reject{ |t| t['key'].downcase == 'other' }
  end

  def self.popular(options = {})
    results = search('*', options.merge(sort: 'rank', order: 'desc'))
    results.records.includes(:repository).reject{|p| p.repository.nil? }
  end

  def normalized_licenses
    read_attribute(:normalized_licenses).presence || [Project.format_license(repository.try(:license))].compact
  end

  def self.format_license(license)
    return nil if license.blank?
    return 'Other' if license.downcase == 'other'
    Spdx.find(license).try(:id) || license
  end

  def normalize_licenses
    if licenses.blank?
      normalized = []
    elsif licenses.length > 150
      normalized = ['Other']
    else
      normalized = licenses.split(/[,\/]/).map do |license|
        Spdx.find(license).try(:id)
      end.compact
      normalized = ['Other'] if normalized.empty?
    end
    self.normalized_licenses = normalized
  end

  def update_repository_async
    RepositoryProjectWorker.perform_async(self.id) if known_repository_host_name.present?
  end

  def known_repository_host_name
    github_name_with_owner || bitbucket_name_with_owner || gitlab_name_with_owner
  end

  def known_repository_host
    return 'GitHub' if github_name_with_owner.present?
    return 'Bitbucket' if bitbucket_name_with_owner
    return 'GitLab' if gitlab_name_with_owner
  end

  def can_have_dependencies?
    return false if platform_class == Project
    platform_class::HAS_DEPENDENCIES
  end

  def can_have_versions?
    return false if platform_class == Project
    platform_class::HAS_VERSIONS
  end

  def release_or_tag
    can_have_versions? ? 'releases' : 'tags'
  end

  def update_repository
    return false unless known_repository_host_name.present?
    r = Repository.create_from_host(known_repository_host, known_repository_host_name)
    return if r.nil?
    unless self.new_record?
      self.repository_id = r.id
      self.forced_save
    end
  end

  def subscribed_repos(user)
    subscriptions.with_repository_subscription.where('repository_subscriptions.user_id = ?', user.id).map(&:repository).uniq
  end

  def check_status(removed = false)
    response = Typhoeus.head(platform_class.check_status_url(self))
    if platform == 'packagist' && response.response_code == 302
      update_attribute(:status, 'Removed')
    elsif platform != 'packagist' && response.response_code == 404
      update_attribute(:status, 'Removed')
    elsif removed
      update_attribute(:status, nil)
    end
  end
end
