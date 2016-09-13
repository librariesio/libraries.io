class Project < ActiveRecord::Base
  include Searchable
  include SourceRank
  HAS_DEPENDENCIES = false
  STATUSES = ['Active', 'Deprecated', 'Unmaintained', 'Help Wanted', 'Removed']
  API_FIELDS = [:name, :platform, :description, :language, :homepage,
                :repository_url, :normalized_licenses, :rank, :status,
                :latest_release_number, :latest_release_published_at]

  validates_presence_of :name, :platform

  # TODO: validate unique name and platform (case senstivite )

  has_many :versions
  has_many :dependencies, -> { group 'project_name' }, through: :versions
  has_many :github_contributions, through: :github_repository
  has_many :contributors, through: :github_contributions, source: :github_user
  has_many :github_tags, through: :github_repository
  has_many :dependents, class_name: 'Dependency'
  has_many :repository_dependencies
  has_many :dependent_manifests, through: :repository_dependencies, source: :manifest
  has_many :dependent_repositories, -> { group('github_repositories.id').order('github_repositories.stargazers_count DESC') }, through: :dependent_manifests, source: :github_repository
  has_many :subscriptions
  has_many :project_suggestions, dependent: :delete_all
  belongs_to :github_repository
  has_one :readme, through: :github_repository

  scope :platform, ->(platform) { where('lower(platform) = ?', platform.try(:downcase)) }
  scope :with_homepage, -> { where("homepage <> ''") }
  scope :with_repository_url, -> { where("repository_url <> ''") }
  scope :without_repository_url, -> { where("repository_url IS ? OR repository_url = ''", nil) }
  scope :with_repo, -> { joins(:github_repository).where('github_repositories.id IS NOT NULL') }
  scope :without_repo, -> { where(github_repository_id: nil) }

  scope :with_license, -> { where("licenses <> ''") }
  scope :without_license, -> { where("licenses IS ? OR licenses = ''", nil) }
  scope :unlicensed, -> { maintained.without_license.with_repo.where("github_repositories.license IS ? OR github_repositories.license = ''", nil) }

  scope :with_versions, -> { where('versions_count > 0') }
  scope :without_versions, -> { where('versions_count < 1') }
  scope :few_versions, -> { where('versions_count < 2') }
  scope :many_versions, -> { where('versions_count > 2') }

  scope :with_dependents, -> { where('dependents_count > 0') }

  scope :with_github_url, -> { where('repository_url ILIKE ?', '%github.com%') }
  scope :with_gitlab_url, -> { where('repository_url ILIKE ?', '%gitlab.com%') }
  scope :with_bitbucket_url, -> { where('repository_url ILIKE ?', '%bitbucket.org%') }
  scope :with_launchpad_url, -> { where('repository_url ILIKE ?', '%launchpad.net%') }
  scope :with_sourceforge_url, -> { where('repository_url ILIKE ?', '%sourceforge.net%') }

  scope :most_watched, -> { joins(:subscriptions).group('projects.id').order("COUNT(subscriptions.id) DESC") }
  scope :most_dependents, -> { with_dependents.order('dependents_count DESC') }

  scope :maintained, -> { where('projects."status" not in (?) OR projects."status" IS NULL', ["Deprecated", "Removed", "Unmaintained"])}
  scope :deprecated, -> { where('projects."status" = ?', "Deprecated")}
  scope :not_removed, -> { where('projects."status" != ? OR projects."status" IS NULL', "Removed")}
  scope :removed, -> { where('projects."status" = ?', "Removed")}
  scope :unmaintained, -> { where('projects."status" = ?', "Unmaintained")}

  scope :indexable, -> { not_removed.includes(:versions, github_repository: :github_tags) }

  scope :bus_factor, -> { maintained.
                          joins(:github_repository)
                         .where('github_repositories.github_contributions_count < 6')
                         .where('github_repositories.github_contributions_count > 0')
                         .where('github_repositories.stargazers_count > 0')
                          }

  after_commit :update_github_repo_async, on: :create
  after_commit :set_dependents_count
  after_commit :update_source_rank_async
  before_save  :normalize_licenses,
               :set_latest_release_published_at,
               :set_latest_release_number,
               :set_language

  before_destroy :destroy_versions

  def to_param
    { name: name, platform: platform.downcase }
  end

  def to_s
    name
  end

  def sync
    platform_class.update(name)
  end

  def async_sync
    RepositoryDownloadWorker.perform_async(platform, name)
  end

  def github_contributions_count
    github_repository.try(:github_contributions_count) || 0
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
    elsif github_tags.published.length > 0
      github_tags.published.all?(&:follows_semver?)
    end
  end

  def is_deprecated?
    status == 'Deprecated'
  end

  def is_removed?
    status == 'Removed'
  end

  def is_unmaintained?
    status == 'Unmaintained'
  end

  def maintained?
    !is_deprecated? && !is_removed? && !is_unmaintained?
  end

  def stable_releases
    versions.select(&:stable?)
  end

  def prereleases
    versions.select(&:prerelease?)
  end

  def latest_stable_version
    @latest_version ||= stable_releases.sort.first
  end

  def latest_stable_tag
    return nil if github_repository.nil?
    github_tags.published.select(&:stable?).sort.first
  end

  def latest_stable_release
    latest_stable_version || latest_stable_tag
  end

  def latest_stable_release_number
    latest_stable_release.try(:number)
  end

  def latest_version
    @latest_version ||= versions.sort.first
  end

  def latest_tag
    return nil if github_repository.nil?
    github_tags.published.order('published_at DESC').first
  end

  def latest_release
    latest_version || latest_tag
  end

  def first_version
    @first_version ||= versions.sort.last
  end

  def first_tag
    return nil if github_repository.nil?
    github_tags.published.order('published_at ASC').first
  end

  def first_release
    first_version || first_tag
  end

  def latest_release_published_at
    read_attribute(:latest_release_published_at) || (latest_release.try(:published_at).presence || updated_at)
  end

  def set_latest_release_published_at
    self.latest_release_published_at = (latest_release.try(:published_at).presence || updated_at)
  end

  def set_latest_release_number
    self.latest_release_number = latest_release.try(:number)
  end

  def latest_release_number
    read_attribute(:latest_release_number) || latest_release.try(:number)
  end

  def keywords
    keywords_array
  end

  def package_manager_url
    Repositories::Base.package_link(self)
  end

  def owner
    return nil unless github_repository
    GithubUser.visible.find_by_login github_repository.owner_name
  end

  def platform_class
    "Repositories::#{platform}".constantize
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
      ids = results['hits']['hits'].map{|h| h['_id']}
    end
  end

  def destroy_versions
    versions.find_each(&:destroy)
  end

  def stars
    github_repository.try(:stargazers_count) || 0
  end

  def forks
    github_repository.try(:forks_count) || 0
  end

  def set_language
    return unless github_repository
    self.language = github_repository.try(:language)
  end

  def repo_name
    github_repository.try(:full_name)
  end

  def description
    if platform == 'Go'
      github_repository.try(:description).presence || read_attribute(:description)
    else
      read_attribute(:description).presence || github_repository.try(:description)
    end
  end

  def homepage
    read_attribute(:homepage).presence || github_repository.try(:homepage)
  end

  def dependent_projects(options = {})
    options = {per_page: 30, page: 1}.merge(options)
    Project.where(id: dependents.joins(:version).limit(options[:per_page]).offset(options[:per_page]*(options[:page].to_i-1)).pluck('DISTINCT versions.project_id')).order('projects.rank DESC')
  end

  def set_dependents_count
    self.update_columns(dependents_count: dependents.joins(:version).pluck('DISTINCT versions.project_id').count)
  end

  def needs_suggestions?
    repository_url.blank? || normalized_licenses.blank?
  end

  def self.undownloaded_repos
    with_github_url.without_repo
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

  def self.facets(options = {})
    Rails.cache.fetch "facet:#{options.to_s.gsub(/\W/, '')}", :expires_in => 1.hour, race_condition_ttl: 2.minutes do
      search('', options).response.facets
    end
  end

  def self.all_languages
    @all_languages ||= Languages::Language.all.map{|l| l.name.downcase}
  end

  def self.popular_languages(options = {})
    facets(options)[:languages][:terms]
  end

  def self.popular_platforms(options = {})
    facets(options)[:platforms][:terms].reject{ |t| t.term.downcase == 'biicode' }
  end

  def self.keywords_badlist
    ['bsd3']
  end

  def self.popular_keywords(options = {})
    facets(options)[:keywords][:terms].reject{ |t| all_languages.include?(t.term.downcase) }.reject{|t| keywords_badlist.include?(t.term.downcase) }
  end

  def self.popular_licenses(options = {})
    facets(options)[:licenses][:terms].reject{ |t| t.term.downcase == 'other' }
  end

  def self.popular(options = {})
    search('*', options.merge(sort: 'rank', order: 'desc')).records.includes(:github_repository, :versions).reject{|p| p.github_repository.nil? }
  end

  def normalized_licenses
    read_attribute(:normalized_licenses).presence || [Project.format_license(github_repository.try(:license))].compact
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

  def update_github_repo_async
    GithubProjectWorker.perform_async(self.id)
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

  def update_github_repo
    name_with_owner = github_name_with_owner
    return false unless name_with_owner.present?
    g = GithubRepository.create_from_github(name_with_owner)
    return if g.nil?
    self.update_columns(github_repository_id: g.id) unless self.new_record?
  end

  def github_url
    return nil if repository_url.blank? || github_name_with_owner.blank?
    "https://github.com/#{github_name_with_owner}"
  end

  def github_name_with_owner
    GithubUrls.parse(repository_url) || GithubUrls.parse(homepage)
  end

  def subscribed_repos(user)
    subscriptions.with_repository_subscription.where('repository_subscriptions.user_id = ?', user.id).map(&:github_repository).uniq
  end
end
