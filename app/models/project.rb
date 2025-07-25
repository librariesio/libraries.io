# frozen_string_literal: true

require "query_counter"

# == Schema Information
#
# Table name: projects
#
#  id                                 :integer          not null, primary key
#  dependent_repos_count              :integer
#  dependents_count                   :integer          default(0), not null
#  deprecation_reason                 :text
#  description                        :text
#  homepage                           :string
#  keywords                           :text
#  keywords_array                     :string           default([]), is an Array
#  language                           :string
#  last_synced_at                     :datetime
#  latest_release_number              :string
#  latest_release_published_at        :datetime
#  latest_stable_release_number       :string
#  latest_stable_release_published_at :datetime
#  license_normalized                 :boolean          default(FALSE)
#  license_set_by_admin               :boolean          default(FALSE)
#  licenses                           :string
#  lifted                             :boolean          default(FALSE)
#  name                               :string
#  normalized_licenses                :string           default([]), is an Array
#  platform                           :string
#  rank                               :integer          default(0)
#  repository_url                     :string
#  runtime_dependencies_count         :integer
#  score                              :integer          default(0), not null
#  score_last_calculated              :datetime
#  status                             :string
#  status_checked_at                  :datetime
#  versions_count                     :integer          default(0), not null
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  latest_version_id                  :integer
#  pm_id                              :integer
#  repository_id                      :integer
#
# Indexes
#
#  index_projects_on_created_at                     (created_at)
#  index_projects_on_dependents_count               (dependents_count)
#  index_projects_on_keywords_array                 (keywords_array) USING gin
#  index_projects_on_lower_language                 (lower((language)::text))
#  index_projects_on_maintained                     (platform,language,id) WHERE (((status)::text = ANY (ARRAY[('Active'::character varying)::text, ('Help Wanted'::character varying)::text])) OR (status IS NULL))
#  index_projects_on_normalized_licenses            (normalized_licenses) USING gin
#  index_projects_on_platform_and_dependents_count  (platform,dependents_count)
#  index_projects_on_platform_and_name              (platform,name) UNIQUE
#  index_projects_on_platform_and_name_lower        (lower((platform)::text), lower((name)::text))
#  index_projects_on_repository_id                  (repository_id)
#  index_projects_on_status                         (status)
#  index_projects_on_status_checked_at              (status_checked_at)
#  index_projects_on_updated_at                     (updated_at)
#  index_projects_on_versions_count                 (versions_count)
#  index_projects_search_on_description             (to_tsvector('simple'::regconfig, COALESCE(description, ''::text))) USING gist
#  index_projects_search_on_name                    ((COALESCE((name)::text, ''::text)) gist_trgm_ops) USING gist
#
class Project < ApplicationRecord
  # We received a 429 from the upstream package repo/index.
  # @param [Integer] retry_after_seconds the optional number of seconds to retry
  #   after, if we have that info available.
  class CheckStatusExternallyRateLimited < StandardError
    attr_reader :retry_after_seconds

    def initialize(retry_after_seconds = nil)
      @retry_after_seconds = retry_after_seconds
      super("Prevented by upstream from making a request.")
    end
  end

  include ProjectSearch
  include SourceRank
  include Status
  include Releases

  include GithubProject
  include GitlabProject
  include BitbucketProject

  HAS_DEPENDENCIES = false
  STATUSES = ["Active", "Deprecated", "Unmaintained", "Help Wanted", "Removed", "Hidden"].freeze
  API_FIELDS = %i[
    code_of_conduct_url
    contributions_count
    contribution_guidelines_url
    dependent_repos_count
    dependents_count
    deprecation_reason
    description
    forks
    funding_urls
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
    repository_status
    repository_url
    security_policy_url
    stars
    status
  ].freeze
  CHECK_STATUS_FREQUENCY_LIMIT = 1.day

  # Currently these are the fields defined in PackageManager::Base::MappingBuilder
  audited only: %w[status name description repository_url homepage keywords_array licenses]

  delegate :code_of_conduct_url, :contribution_guidelines_url, :funding_urls, :security_policy_url, to: :repository, allow_nil: true

  validates :name, :platform, presence: true
  validates :status, inclusion: { in: STATUSES, allow_blank: true }

  belongs_to :repository
  has_many :versions, dependent: :destroy
  belongs_to :latest_version, class_name: "Version"
  has_many :dependencies, -> { group "project_name" }, through: :versions
  has_many :contributions, through: :repository
  has_many :contributors, through: :contributions, source: :repository_user
  has_many :tags, through: :repository
  has_many :published_tags, -> { where("published_at IS NOT NULL") }, through: :repository, class_name: "Tag"
  has_many :dependents, class_name: "Dependency"
  has_many :dependent_versions, through: :dependents, source: :version, class_name: "Version"
  has_many :dependent_projects, -> { group("projects.id").order("projects.rank DESC NULLS LAST") }, through: :dependent_versions, source: :project, class_name: "Project"
  # TODO: unscope().group() can be replaced with regroup() in rails 7.1: https://github.com/rails/rails/pull/47010
  has_many :dependent_repositories, -> { unscope(:group).group("repositories.id").reorder("repositories.rank DESC NULLS LAST, repositories.stargazers_count DESC") }, through: :dependent_projects, source: :repository

  has_many :subscriptions, dependent: :destroy
  has_many :project_suggestions, dependent: :delete_all
  has_many :registry_permissions, dependent: :delete_all
  has_many :project_mutes, dependent: :delete_all
  has_many :registry_users, through: :registry_permissions
  has_one :readme, through: :repository
  has_many :repository_maintenance_stats, through: :repository

  scope :updated_within, ->(start, stop) { where("updated_at >= ? and updated_at <= ? ", start, stop).order(updated_at: :asc) }

  scope :platform, ->(platforms) { where(platform: Array.wrap(platforms).map { |platform| PackageManager::Base.format_name(platform) }) }
  scope :lower_platform, ->(platform) { where("lower(projects.platform) = ?", platform.try(:downcase)) }
  scope :lower_name, ->(name) { where("lower(projects.name) = ?", name.try(:downcase)) }

  scope :with_homepage, -> { where("homepage <> ''") }
  scope :with_repository_url, -> { where("repository_url <> ''") }
  scope :without_repository_url, -> { where("repository_url IS ? OR repository_url = ''", nil) }
  scope :with_repo, -> { joins(:repository).where("repositories.id IS NOT NULL") }
  scope :without_repo, -> { where(repository_id: nil) }
  scope :with_description, -> { where("projects.description <> ''") }

  scope :with_license, -> { where("licenses <> ''") }
  scope :without_license, -> { where("licenses IS ? OR licenses = ''", nil) }
  scope :unlicensed, -> { maintained.without_license.with_repo.where("repositories.license IS ? OR repositories.license = ''", nil) }

  scope :with_versions, -> { where("versions_count > 0") }
  scope :without_versions, -> { where("versions_count < 1") }
  scope :few_versions, -> { where("versions_count < 2") }
  scope :many_versions, -> { where("versions_count > 2") }

  scope :with_dependents, -> { where("dependents_count > 0") }
  scope :with_dependent_repos, -> { where("dependent_repos_count > 0") }

  scope :with_github_url, -> { where("repository_url ILIKE ?", "%github.com%") }
  scope :with_gitlab_url, -> { where("repository_url ILIKE ?", "%gitlab.com%") }
  scope :with_bitbucket_url, -> { where("repository_url ILIKE ?", "%bitbucket.org%") }
  scope :with_launchpad_url, -> { where("repository_url ILIKE ?", "%launchpad.net%") }
  scope :with_sourceforge_url, -> { where("repository_url ILIKE ?", "%sourceforge.net%") }

  scope :most_watched, -> { joins(:subscriptions).group("projects.id").order(Arel.sql("COUNT(subscriptions.id) DESC")) }
  scope :most_dependents, -> { with_dependents.order(Arel.sql("dependents_count DESC")) }
  scope :most_dependent_repos, -> { with_dependent_repos.order(Arel.sql("dependent_repos_count DESC")) }

  scope :visible, -> { where('projects."status" != ? OR projects."status" IS NULL', "Hidden") }
  scope :maintained, -> { where('projects."status" in (?) OR projects."status" IS NULL', ["Active", "Help Wanted"]) }
  scope :deprecated, -> { where('projects."status" = ?', "Deprecated") }
  scope :not_removed, -> { where('projects."status" not in (?) OR projects."status" IS NULL', %w[Removed Hidden]) }
  scope :removed, -> { where('projects."status" = ?', "Removed") }
  scope :unmaintained, -> { where('projects."status" = ?', "Unmaintained") }
  scope :hidden, -> { where('projects."status" = ?', "Hidden") }
  scope :removed_or_deprecated, -> { where('projects."status" in (?)', %w[Removed Deprecated]) }

  scope :indexable, -> { not_removed.includes(:repository) }

  scope :unsung_heroes, lambda {
    maintained
      .with_repo
      .where("repositories.stargazers_count < 100")
      .where("projects.dependent_repos_count > 1000")
  }

  scope :digital_infrastructure, lambda {
    not_removed
      .with_repo
      .where("projects.dependent_repos_count > ?", 10000)
  }

  scope :hacker_news, -> { with_repo.where("repositories.stargazers_count > 0").order(Arel.sql("((repositories.stargazers_count-1)/POW((EXTRACT(EPOCH FROM current_timestamp-repositories.created_at)/3600)+2,1.8)) DESC")) }
  scope :recently_created, -> { with_repo.where("repositories.created_at > ?", 2.weeks.ago) }

  after_commit :update_repository_async, on: :create
  after_commit :update_source_rank_async, on: %i[create update]
  after_commit :send_project_updated, on: %i[create update], if: :saved_change_to_updated_at?
  before_save  :update_details
  before_destroy :destroy_versions
  before_destroy :create_deleted_project
  after_create :destroy_deleted_project

  include PgSearch::Model
  DB_SEARCH_OPTIONS = {
    order_within_rank: "latest_release_published_at DESC",
    ranked_by: ":trigram",
    against: %i[name],
    using: {
      trigram: {},
    },
  }.freeze
  pg_search_scope :db_search, DB_SEARCH_OPTIONS

  def self.total
    Rails.cache.fetch "projects:total", expires_in: 1.day, race_condition_ttl: 2.minutes do
      all.count
    end
  end

  def to_param
    { name: name, platform: platform.downcase }
  end

  def to_s
    name
  end

  def manual_sync(force_sync_dependencies: true)
    StructuredLog.capture("PROJECT_MANUAL_SYNC",
                          {
                            platform: platform,
                            name: name,
                            last_synced_at: last_synced_at,
                          })
    async_sync(force_sync_dependencies: force_sync_dependencies)
    update_repository_async
  end

  def forced_save
    self.updated_at = Time.zone.now
    save
  end

  def async_sync(force_sync_dependencies: false)
    return unless platform_class_exists?

    sync_classes.each { |sync_class| PackageManagerDownloadWorker.perform_async(sync_class.name, name, nil, "project", 0, force_sync_dependencies) }
    CheckStatusWorker.perform_async(id)
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
    set_latest_version
    set_latest_release_published_at
    set_latest_release_number
    set_latest_stable_release_info
    set_runtime_dependencies_count
    set_language
  end

  def keywords
    (Array.wrap(keywords_array) + Array.wrap(repository.try(:keywords) || [])).flatten.compact.uniq(&:downcase)
  end

  def package_manager_url(version = nil)
    platform_class.package_link(self, version)
  end

  def repository_license
    repository&.license
  end

  def repository_status
    repository&.status
  end

  def download_url(version = nil)
    platform_class.download_url(self, version) if version
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
    return nil unless repository && repository.host_type == "GitHub"

    RepositoryUser.host("GitHub").visible.login(repository.owner_name).first
  end

  def platform_class
    "PackageManager::#{platform}".constantize
  end

  def platform_class_exists?
    Kernel.const_defined?("PackageManager::#{platform}")
  end

  def platform_name
    platform_class.formatted_name
  end

  def color
    Linguist::Language[language].try(:color) || (platform_class_exists? && platform_class.try(:color))
  end

  def mlt
    Project.where(id: mlt_ids).limit(5)
  rescue StandardError
    []
  end

  def mlt_ids
    Rails.cache.fetch "projects:#{id}:mlt_ids", expires_in: 1.week do
      results = Project.__elasticsearch__.client.mlt(id: id, index: "projects", type: "project", mlt_fields: "keywords_array,platform,description,repository_url", min_term_freq: 1, min_doc_freq: 2)
      results["hits"]["hits"].map { |h| h["_id"] }
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
    if platform == "Go"
      repository.try(:description).presence || read_attribute(:description)
    else
      read_attribute(:description).presence || repository.try(:description)
    end
  end

  def homepage
    read_attribute(:homepage).presence || repository.try(:homepage)
  end

  def set_dependents_count_async
    return if destroyed?

    SetProjectDependentsCountWorker.perform_async(id)
  end

  def set_dependents_count
    return if destroyed?

    # These are optimized query alternatives to the :dependent_projects and :dependent_repositories associations,
    # however they still need timeouts for extremely popular projects.
    new_dependents_count = ActiveRecord::Base.connection.with_statement_timeout(30.minutes.to_i) do
      Version.where(id: dependents.select(:version_id)).select(:project_id).distinct.count
    end
    new_dependent_repos_count = ActiveRecord::Base.connection.with_statement_timeout(60.minutes.to_i) do
      Version.where(id: dependents.select(:version_id)).joins(:project).select("projects.repository_id").distinct.count
    end

    updates = {}
    updates[:dependents_count] = new_dependents_count if read_attribute(:dependents_count) != new_dependents_count
    updates[:dependent_repos_count] = new_dependent_repos_count if read_attribute(:dependent_repos_count) != new_dependent_repos_count
    update_columns(updates) if updates.present?
  end

  def send_project_updated
    # this should be a cheap no-op if we remove all the
    # receives_all_project_updates WebHook, so that's an emergency off switch if
    # required. Each webhook must be its own sidekiq job so it can be
    # independently retried if failing.
    WebHook.receives_all_project_updates.pluck(:id).each do |web_hook_id|
      StructuredLog.capture("WEB_HOOK_ABOUT_TO_QUEUE",
                            {
                              webhook_id: web_hook_id,
                              project_id: id,
                              project_platform: platform,
                              project_name: name,
                            })
      ProjectUpdatedWorker.perform_async(id, web_hook_id)
    end
  end

  def needs_suggestions?
    repository_url.blank? || normalized_licenses.blank?
  end

  def self.undownloaded_repos
    with_github_url.or(with_gitlab_url).or(with_bitbucket_url).without_repo
  end

  def self.license(license)
    where("projects.normalized_licenses @> ?", Array(license).to_postgres_array(omit_quotes: true))
  end

  def self.keyword(keyword)
    where("projects.keywords_array @> ?", Array(keyword).to_postgres_array(omit_quotes: true))
  end

  def self.keywords(keywords)
    where("projects.keywords_array && ?", Array(keywords).to_postgres_array(omit_quotes: true))
  end

  def self.language(language)
    where("lower(projects.language) = ?", language.try(:downcase))
  end

  def self.all_languages
    @all_languages ||= Linguist::Language.all.map { |l| l.name.downcase }
  end

  def self.popular_languages(options = {})
    facets(options)[:languages].language.buckets
  end

  def self.popular_licenses(options = {})
    facets(options)[:licenses].normalized_licenses.buckets.reject { |t| t["key"].downcase == "other" }
  end

  def self.popular(options = {})
    results = search("*", options.merge(sort: "rank", order: "desc"))
    results.records.includes(:repository).reject { |p| p.repository.nil? }
  end

  def normalized_licenses
    read_attribute(:normalized_licenses).presence || [Project.format_license(repository.try(:license))].compact
  end

  def self.format_license(license)
    return nil if license.blank?
    return "Other" if license.downcase == "other"

    Spdx.find(license).try(:id) || license
  end

  def self.find_best(*args)
    find_best!(*args)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def self.find_best!(platform, name, includes = [])
    find_exact(platform, name, includes) ||
      find_lower(platform, name, includes) ||
      find_with_package_manager!(platform, name, includes)
  end

  private_class_method def self.find_exact(platform, name, includes = [])
    visible
      .platform(platform)
      .where(name: name)
      .includes(includes.present? ? includes : nil)
      .first
  end

  private_class_method def self.find_lower(platform, name, includes = [])
    visible
      .lower_platform(platform)
      .lower_name(name)
      .includes(includes.present? ? includes : nil)
      .first
  end

  # Finds projects with the given names based on lowercase, using package-manager-specific
  # rules if they exist.
  #
  # @param platform [string] Platform name, case-insensitive.
  # @param names [<Array<String>>] A list of project names for lookup, case-insensitive.
  # @param includes [Array] A list of AR-includes, optional.
  # @return [Hash<String, [Project, nil]>] A mapping of lookup names to their found project,
  #   or nil if the Project wasn't found.
  def self.find_all_with_package_manager!(platform, names = [], includes = [])
    platform_class = PackageManager::Base.find(platform)
    raise ActiveRecord::RecordNotFound if platform_class.nil?

    scope = visible
      .lower_platform(platform)
      .includes(includes.present? ? includes : nil)

    # PEP 503 requires that Python repos have a /simple API that is queryable by a "normalized" name,
    # which is the canonical name lowercased with runs of "-_." replaced by a single "-".
    # https://peps.python.org/pep-0503/#normalized-names
    # As of writing, all Pypi packages in Libraries can be queried on Pypi's API by their normalized name.
    if platform_class == PackageManager::Pypi
      normalized_names = names.map { |name| Bibliothecary::Parsers::Pypi.normalize_name(name) }
      projects = scope.where("lower(regexp_replace(name, '[-_.]+', '-', 'ig')) in (?)", normalized_names)

      names.to_h do |name|
        [
          name,
          projects.find { |project| Bibliothecary::Parsers::Pypi.normalize_name(project.name) == Bibliothecary::Parsers::Pypi.normalize_name(name) },
        ]
      end
    else
      projects = scope.where("lower(name) in (?)", names.map(&:downcase))

      names.to_h do |name|
        [name, projects.find { |project| project.name.downcase == name }]
      end
    end
  end

  # This is a single-name lookup using find_all_with_package_manager!().
  private_class_method def self.find_with_package_manager!(platform, name, _includes = [])
    find_all_with_package_manager!(platform, [name]).fetch(name, nil) || raise(ActiveRecord::RecordNotFound)
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
    RepositoryProjectWorker.perform_async(id) if known_repository_host_name.present?
  end

  def known_repository_host_name
    github_name_with_owner || bitbucket_name_with_owner || gitlab_name_with_owner
  end

  def known_repository_host
    return "GitHub" if github_name_with_owner.present?
    return "Bitbucket" if bitbucket_name_with_owner
    return "GitLab" if gitlab_name_with_owner

    nil
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
    can_have_versions? ? "releases" : "tags"
  end

  def update_repository
    return false unless known_repository_host_name.present?

    r = Repository.create_from_host(known_repository_host, known_repository_host_name)
    return if r.nil?

    unless new_record?
      self.repository_id = r.id
      forced_save
    end
  end

  def update_tags
    return unless repository

    benchmark = nil

    qcount = QueryCounter.count do
      benchmark = Benchmark.measure do
        repository.download_tags
      end
    end

    Rails.logger.debug("Project#update_tags platform=#{platform.downcase} name=#{name} qcount=#{qcount} benchmark:#{(benchmark.real * 1000).round(2)}ms")
  rescue StandardError => e
    Rails.logger.error("Project#update_tags error #{e.inspect}")
    nil
  end

  def subscribed_repos(user)
    subscriptions.with_repository_subscription.where("repository_subscriptions.user_id = ?", user.id).map(&:repository).uniq
  end

  # This is an optimized query alternative to the :dependent_repositories association. It can be
  # very slow for super popular repositories, so cap the timeout to 5 seconds.
  def dependent_repositories_optimized(limit, offset = 0)
    repo_ids = ActiveRecord::Base.connection.with_statement_timeout(5) do
      Version
        .where(id: dependents.select(:version_id))
        .joins(:project)
        .select("projects.repository_id")
        .distinct
        .count
    rescue ActiveRecord::QueryCanceled
      []
    end

    Repository
      .where(id: repo_ids)
      .order("repositories.rank DESC NULLS LAST, repositories.stargazers_count DESC")
      .limit(limit)
      .offset(offset)
  end

  def dependent_repos_top_ten
    dependent_repositories_optimized(10)
  end

  def check_status
    return if status_checked_at && status_checked_at > CHECK_STATUS_FREQUENCY_LIMIT.ago

    downcased_platform = platform.downcase
    url = platform_class.check_status_url(self)
    update_column(:status_checked_at, DateTime.current)

    return if url.blank?

    # "Hidden" is a state set by admins, and we don't want to override that decision.
    return if hidden?

    response = Typhoeus.get(url)

    StructuredLog.capture("CHECK_STATUS_CHANGE", { platform: platform, name: name, status_code: response.response_code }) if downcased_platform == "npm"

    if downcased_platform.in?(%w[packagist npm]) && [302, 404].include?(response.response_code)
      # NPM 302 happens with privately scoped packages, which should be considered Removed.
      update(status: "Removed", audit_comment: "Response #{response.response_code}")
    elsif downcased_platform == "npm" && response.response_code == 200 && npm_unpublished_response?(JSON.parse(response.body))
      update(status: "Removed", audit_comment: "Response #{response.response_code} + unpublished.")
    elsif downcased_platform == "go" && [302, 400, 404].include?(response.response_code)
      # pkg.go.dev can be 404 on first-hit for a new package (or alias for the package), so ensure that the package existed in the past
      # by ensuring its age is old enough to not be just uncached by pkg.go.dev yet.
      update(status: "Removed", audit_comment: "Response #{response.response_code}") if created_at < 1.week.ago
    elsif !downcased_platform.in?(%w[packagist go]) && [400, 404, 410].include?(response.response_code)
      update(status: "Removed", audit_comment: "Response #{response.response_code}")
    elsif response.timed_out? || response.response_code == 429 || (response.response_code >= 500 && response.response_code <= 599) || response.response_code == 0
      # failure could be a problem checking so let's just log for now
      StructuredLog.capture("CHECK_STATUS_FAILURE", { platform: platform, name: name, status_code: response.response_code })
      raise CheckStatusExternallyRateLimited, 5.minutes if response.response_code == 429
    elsif can_have_entire_package_deprecated?
      result = platform_class.deprecation_info(self)
      if result[:is_deprecated]
        update(status: "Deprecated", deprecation_reason: result[:message], audit_comment: "Reason '#{result[:message]}'")
      elsif response.response_code >= 200 && response.response_code <= 299 # in case package was accidentally marked as deprecated (their logic or ours), mark it as not deprecated
        update(status: nil, deprecation_reason: nil, audit_comment: "Response #{response.response_code}")
      end
    elsif response.response_code >= 200 && response.response_code <= 299
      update(status: nil, audit_comment: "Response #{response.response_code}")
    end
    # only update status to nil if the response code is a success
  end

  # The Web url returns 404 for unpublished packages, bu the API returns 200.
  # This logic should determine if a package was removed from NPM, but it's possible there
  # may be other permutations of the response that suggest it was unpublished/removed.
  def npm_unpublished_response?(json)
    json.dig("time", "unpublished").present? && # unpublished packages will have a list of unpublished versions
      !json.key?("versions") # published packages should have a "versions" key
  end

  def unique_project_requirement_ranges
    dependents.select("dependencies.requirements").distinct.pluck(:requirements)
  end

  def potentially_outdated?
    current_version = SemanticRange.clean(latest_release_number)
    unique_project_requirement_ranges.compact.sort.any? do |range|
      !(SemanticRange.gtr(current_version, range, false, platform) ||
      SemanticRange.satisfies(current_version, range, false, platform))
    rescue StandardError
      false
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
      registry_permissions.find { |rp| rp.registry_user == owner }.destroy
    end
  end

  def find_version!(version_name)
    version_name = versions.pluck(:number).max if version_name == "latest"

    version = versions.find_by_number(version_name)

    raise ActiveRecord::RecordNotFound if version.nil?

    version
  end

  def update_maintenance_stats_async(priority: :medium)
    RepositoryMaintenanceStatWorker.enqueue(repository.id, priority: priority) unless repository.nil?
  end

  def reformat_repository_url
    repository_url = URLParser.try_all(self.repository_url)
    update(repository_url: repository_url)
  end

  def mailing_list(include_prereleases: false)
    subscribed = subscriptions
    subscribed = subscribed.include_prereleases if include_prereleases

    subs = subscribed.includes(:user).users_present.where(users: { emails_enabled: true }).map(&:user)
    subs += subscribed.includes(repository_subscription: [:user]).users_nil.where(repository_subscriptions: { users: { emails_enabled: true } }).map { |sub| sub.repository_subscription&.user }
    subs.compact!
    subs.uniq!
    mutes = project_mutes.pluck(:user_id).to_set
    subs.reject { |sub| mutes.include?(sub.id) }
  end

  # @return [Array(String)] All possible Version#repository_sources for
  #                         this package, unordered
  def repository_sources
    versions
      .flat_map(&:repository_sources)
      .compact
      .uniq
  end

  def find_version(version)
    # Avoid a database call if we can help it.
    if association(:versions).loaded? && !versions.empty?
      versions.find { |v| v.number == version }
    else
      versions.find_by(number: version)
    end
  end

  private

  def spdx_license
    licenses
      .downcase
      .sub(/^\(/, "")
      .sub(/\)$/, "")
      .split("or")
      .flat_map { |l| l.split("and") }
      .map { |l| manual_license_format(l) }
      .flat_map { |l| l.split(/[,\/]/) }
      .map(&Spdx.method(:find))
      .compact
      .map(&:id)
  end

  def manual_license_format(license)
    # fixes "Apache License, Version 2.0" being incorrectly split on the comma
    license
      .gsub("apache license, version", "apache license version")
      .gsub("apache software license, version", "apache software license version")
  end
end
