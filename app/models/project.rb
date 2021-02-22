# frozen_string_literal: true
class Project < ApplicationRecord
  include ProjectSearch
  include SourceRank
  include Status
  include Releases

  include GithubProject
  include GitlabProject
  include BitbucketProject

  HAS_DEPENDENCIES = false
  STATUSES = ['Active', 'Deprecated', 'Unmaintained', 'Help Wanted', 'Removed', 'Hidden'].freeze
  API_FIELDS = %i[
    dependent_repos_count
    dependents_count
    deprecation_reason
    description
    forks
    homepage
    keywords
    language
    latest_download_url
    latest_release_number
    latest_release_published_at
    latest_stable_release_number
    latest_stable_release_published_at
    license_normalized
    licenses
    name
    normalized_licenses
    package_manager_url
    platform
    rank
    repository_license
    repository_url
    stars
    status
  ].freeze

  validates :name, :platform, presence: true
  validates :name, uniqueness: { scope: :platform, case_sensitive: true }
  validates :status, inclusion: { in: STATUSES, allow_blank: true }

  belongs_to :repository
  has_many :versions, dependent: :destroy
  has_many :dependencies, -> { group 'project_name' }, through: :versions
  has_many :contributions, through: :repository
  has_many :contributors, through: :contributions, source: :repository_user
  has_many :tags, through: :repository
  has_many :published_tags, -> { where('published_at IS NOT NULL') }, through: :repository, class_name: 'Tag'
  has_many :dependents, class_name: 'Dependency'
  has_many :dependent_versions, through: :dependents, source: :version, class_name: 'Version'
  has_many :dependent_projects, -> { group('projects.id').order('projects.rank DESC NULLS LAST') }, through: :dependent_versions, source: :project, class_name: 'Project'
  has_many :repository_dependencies
  has_many :dependent_repositories, -> { group('repositories.id').order('repositories.rank DESC NULLS LAST, repositories.stargazers_count DESC') }, through: :repository_dependencies, source: :repository
  has_many :subscriptions, dependent: :destroy
  has_many :project_suggestions, dependent: :delete_all
  has_many :registry_permissions, dependent: :delete_all
  has_many :registry_users, through: :registry_permissions
  has_one :readme, through: :repository
  has_many :repository_maintenance_stats, through: :repository

  scope :updated_within, ->(start, stop) { where('updated_at >= ? and updated_at <= ? ', start, stop).order(updated_at: :asc) }
  scope :least_recently_updated_stats, -> { joins(:repository_maintenance_stats).group('projects.id').where.not(repository: nil).order(Arel.sql('max(repository_maintenance_stats.updated_at) ASC')) }
  scope :no_existing_stats, -> { includes(:repository_maintenance_stats).where(repository_maintenance_stats: {id: nil}).where.not(repository: nil) }

  scope :platform, ->(platform) { where(platform: PackageManager::Base.format_name(platform)) }
  scope :lower_platform, ->(platform) { where('lower(projects.platform) = ?', platform.try(:downcase)) }
  scope :lower_name, ->(name) { where('lower(projects.name) = ?', name.try(:downcase)) }

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

  scope :most_watched, -> { joins(:subscriptions).group('projects.id').order(Arel.sql("COUNT(subscriptions.id) DESC")) }
  scope :most_dependents, -> { with_dependents.order(Arel.sql('dependents_count DESC')) }
  scope :most_dependent_repos, -> { with_dependent_repos.order(Arel.sql('dependent_repos_count DESC')) }

  scope :visible, -> { where('projects."status" != ? OR projects."status" IS NULL', "Hidden")}
  scope :maintained, -> { where('projects."status" not in (?) OR projects."status" IS NULL', ["Deprecated", "Removed", "Unmaintained", "Hidden"])}
  scope :deprecated, -> { where('projects."status" = ?', "Deprecated")}
  scope :not_removed, -> { where('projects."status" not in (?) OR projects."status" IS NULL', ["Removed", "Hidden"])}
  scope :removed, -> { where('projects."status" = ?', "Removed")}
  scope :unmaintained, -> { where('projects."status" = ?', "Unmaintained")}
  scope :hidden, -> { where('projects."status" = ?', "Hidden")}

  scope :indexable, -> { not_removed.includes(:repository) }

  scope :unsung_heroes, -> { maintained
                             .with_repo
                             .where('repositories.stargazers_count < 100')
                             .where('projects.dependent_repos_count > 1000') }

  scope :digital_infrastructure, -> { not_removed
                             .with_repo
                             .where('projects.dependent_repos_count > ?', 10000)}

  scope :bus_factor, -> { maintained
                          .joins(:repository)
                          .where('repositories.contributions_count < 6')
                          .where('repositories.contributions_count > 0')
                          .where('repositories.stargazers_count > 0')}

  scope :hacker_news, -> { with_repo.where('repositories.stargazers_count > 0').order(Arel.sql("((repositories.stargazers_count-1)/POW((EXTRACT(EPOCH FROM current_timestamp-repositories.created_at)/3600)+2,1.8)) DESC")) }
  scope :recently_created, -> { with_repo.where('repositories.created_at > ?', 2.weeks.ago)}

  after_commit :update_repository_async, on: :create
  after_commit :set_dependents_count, on: [:create, :update]
  after_commit :update_source_rank_async, on: [:create, :update]
  before_save  :update_details
  before_destroy :destroy_versions
  before_destroy :create_deleted_project
  after_create :destroy_deleted_project

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
    forced_save
  end

  def forced_save
    self.updated_at = Time.zone.now
    save
  end

  def set_last_synced_at
    update_attribute(:last_synced_at, Time.zone.now)
  end

  def async_sync
    sync_classes.each{ |sync_class| PackageManagerDownloadWorker.perform_async(sync_class.name, name) }
    CheckStatusWorker.perform_async(id, status == "Removed")
  end

  def sync_classes
    return platform_class.providers(self) if platform_class::HAS_MULTIPLE_REPO_SOURCES

    [platform_class]
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

  def update_details
    normalize_licenses
    set_latest_release_published_at
    set_latest_release_number
    set_latest_stable_release_info
    set_runtime_dependencies_count
    set_language
  end

  def keywords
    (Array(keywords_array) + Array(repository.try(:keywords) || [])).compact.uniq(&:downcase)
  end

  def package_manager_url(version = nil)
    platform_class.package_link(self, version)
  end

  def repository_license
    repository&.license
  end

  def download_url(version = nil)
    platform_class.download_url(name, version) if version
  end

  def latest_download_url
    download_url(latest_release_number)
  end

  def documentation_url(version = nil)
    platform_class.documentation_url(name, version)
  end

  def install_instructions(version = nil)
    platform_class.install_instructions(self, version)
  end

  def owner
    return nil unless repository && repository.host_type == 'GitHub'
    RepositoryUser.host('GitHub').visible.login(repository.owner_name).first
  end

  def platform_class
    "PackageManager::#{platform}".constantize
  end

  def platform_name
    platform_class.formatted_name
  end

  def color
    Linguist::Language[language].try(:color) || platform_class.try(:color)
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

  def create_deleted_project
    DeletedProject.create_from_platform_and_name!(platform, name)
  end

  def destroy_deleted_project
    # this happens when bringing a project back to life
    digest = DeletedProject.digest_from_platform_and_name(platform, name)
    DeletedProject.where(digest: digest).destroy_all
  end

  def stars
    repository.try(:stargazers_count) || 0
  end

  def forks
    repository.try(:forks_count) || 0
  end

  def watchers
    repository.try(:subscribers_count) || 0
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
    new_dependents_count = dependents.joins(:version).pluck(Arel.sql('DISTINCT versions.project_id')).count
    new_dependent_repos_count = dependent_repos_fast_count

    updates = {}
    updates[:dependents_count] = new_dependents_count if read_attribute(:dependents_count) != new_dependents_count
    updates[:dependent_repos_count] = new_dependent_repos_count if read_attribute(:dependent_repos_count) != new_dependent_repos_count
    self.update_columns(updates) if updates.present?
  end

  def needs_suggestions?
    repository_url.blank? || normalized_licenses.blank?
  end

  def self.undownloaded_repos
    with_github_url.or(with_gitlab_url).or(with_bitbucket_url).without_repo
  end

  def self.license(license)
    where("projects.normalized_licenses @> ?", Array(license).to_postgres_array(true))
  end

  def self.keyword(keyword)
    where("projects.keywords_array @> ?", Array(keyword).to_postgres_array(true))
  end

  def self.keywords(keywords)
    where("projects.keywords_array && ?", Array(keywords).to_postgres_array(true))
  end

  def self.language(language)
    where('lower(projects.language) = ?', language.try(:downcase))
  end

  def self.all_languages
    @all_languages ||= Linguist::Language.all.map{|l| l.name.downcase}
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
    facets(options)[:licenses].normalized_licenses.buckets.reject{ |t| t['key'].casecmp('other').zero? }
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

  def self.find_best(*args)
    find_best!(*args)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def self.find_best!(platform, name, includes=[])
    find_exact(platform, name, includes) ||
      find_lower(platform, name, includes) ||
      find_with_package_manager!(platform, name, includes)
  end

  private_class_method def self.find_exact(platform, name, includes=[])
    visible
      .platform(platform)
      .where(name: name)
      .includes(includes.present? ? includes : nil)
      .first
  end

  private_class_method def self.find_lower(platform, name, includes=[])
    visible
      .lower_platform(platform)
      .lower_name(name)
      .includes(includes.present? ? includes : nil)
      .first
  end

  private_class_method def self.find_with_package_manager!(platform, name, includes=[])
    platform_class = PackageManager::Base.find(platform)
    raise ActiveRecord::RecordNotFound if platform_class.nil?
    names = platform_class
      .project_find_names(name)
      .map(&:downcase)

    visible
      .lower_platform(platform)
      .where("lower(projects.name) in (?)", names)
      .includes(includes.present? ? includes : nil)
      .first!
  end

  def normalize_licenses
    # avoid changing the license if it has been set directly through the admin console
    return if license_set_by_admin?

    self.normalized_licenses =
      if licenses.blank?
        []

      elsif licenses.length > 150
        self.license_normalized = true
        ["Other"]

      else
        spdx = spdx_license

        if spdx.empty?
          self.license_normalized = true
          ["Other"]

        else
          self.license_normalized = spdx.first != licenses
          spdx

        end
      end
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

  def can_have_entire_package_deprecated?
    return false if platform_class == Project
    platform_class::ENTIRE_PACKAGE_CAN_BE_DEPRECATED
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

  def dependent_repos_view_query(limit, offset=0)
    sql = "SELECT *
           FROM   repositories
           WHERE  id IN
                  (
                        SELECT   repository_id
                        FROM     project_dependent_repositories
                        WHERE    project_id = ?
                        ORDER BY rank DESC nulls last,
                                 stargazers_count DESC limit ? offset ?);"

    Repository.find_by_sql([sql, id, limit, offset])
  end

  def dependent_repos_top_ten
    dependent_repos_view_query(10)
  end

  def dependent_repos_fast_count
    ProjectDependentRepository.where(project_id: id).count
  end

  def check_status(removed = false)
    url = platform_class.check_status_url(self)
    return if url.blank?
    response = Typhoeus.head(url)
    if platform.downcase == 'packagist' && response.response_code == 302
      update_attribute(:status, 'Removed')
    elsif platform.downcase == 'pypi' && response.response_code == 404
      # TODO: remove this stanza once this bug is fixed: https://github.com/pypa/warehouse/issues/3709#issuecomment-754973958
      update_attribute(:status, 'Deprecated')
    elsif platform.downcase != 'packagist' && [400, 404, 410].include?(response.response_code)
      update_attribute(:status, 'Removed')
    elsif platform.downcase == 'clojars' && response.response_code == 404
      update_attribute(:status, 'Removed')
    elsif can_have_entire_package_deprecated?
      result = platform_class.deprecation_info(name)
      if result[:is_deprecated]
        update_attribute(:status, 'Deprecated')
        update_attribute(:deprecation_reason, result[:message])
      end
    elsif removed
      update_attribute(:status, nil)
    end
  end

  def unique_repo_requirement_ranges
    repository_dependencies.select('repository_dependencies.requirements').distinct.pluck(:requirements)
  end

  def unique_project_requirement_ranges
    dependents.select('dependencies.requirements').distinct.pluck(:requirements)
  end

  def unique_requirement_ranges
    (unique_repo_requirement_ranges + unique_project_requirement_ranges).uniq
  end

  def potentially_outdated?
    current_version = SemanticRange.clean(latest_release_number)
    unique_requirement_ranges.compact.sort.any? do |range|
      begin
        !(SemanticRange.gtr(current_version, range, false, platform) ||
        SemanticRange.satisfies(current_version, range, false, platform))
      rescue
        false
      end
    end
  end

  def download_registry_users
    # download owner data
    owner_json = platform_class.download_registry_users(name)
    owners = []

    return unless owner_json.present?

    # find or create registry users
    owner_json.each do |user|
      r = RegistryUser.find_or_create_by(platform: platform, uuid: user[:uuid])
      r.email = user[:email]
      r.login = user[:login]
      r.name = user[:name]
      r.url = user[:url]
      r.save if r.changed?
      owners << r
    end

    # update registry permissions
    existing_permissions = registry_permissions.includes(:registry_user).all
    existing_owners = existing_permissions.map(&:registry_user)

    # add new owners
    new_owners = owners - existing_owners
    new_owners.each do |owner|
      registry_permissions.create(registry_user: owner)
    end

    # remove missing users
    removed_owners = existing_owners - owners
    removed_owners.each do |owner|
      registry_permissions.find{|rp| rp.registry_user == owner}.destroy
    end
  end

  def find_version!(version_name)
    if version_name == 'latest'
      version_name = versions.pluck(:number).sort.last
    end

    version = versions.find_by_number(version_name)

    raise ActiveRecord::RecordNotFound if version.nil?

    version
  end

  def update_maintenance_stats_async(priority: :medium)
    RepositoryMaintenanceStatWorker.enqueue(repository.id, priority: priority) unless repository.nil?
  end

  def reformat_repository_url
    repository_url = URLParser.try_all(self.repository_url)
    update_attributes(repository_url: repository_url)
  end

  private

  def spdx_license
    licenses
      .downcase
      .sub(/^\(/, "")
      .sub(/\)$/, "")
      .split("or")
      .flat_map { |l| l.split("and") }
      .flat_map { |l| l.split(/[,\/]/) }
      .map(&Spdx.method(:find))
      .compact
      .map(&:id)
  end
end
