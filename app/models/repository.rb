# frozen_string_literal: true

# == Schema Information
#
# Table name: repositories
#
#  id                             :integer          not null, primary key
#  contributions_count            :integer          default(0), not null
#  default_branch                 :string
#  description                    :string
#  fork                           :boolean
#  fork_policy                    :string
#  forks_count                    :integer
#  full_name                      :string
#  has_audit                      :string
#  has_changelog                  :string
#  has_coc                        :string
#  has_contributing               :string
#  has_issues                     :boolean
#  has_license                    :string
#  has_pages                      :boolean
#  has_readme                     :string
#  has_threat_model               :string
#  has_wiki                       :boolean
#  homepage                       :string
#  host_domain                    :string
#  host_type                      :string
#  keywords                       :string           default([]), is an Array
#  language                       :string
#  last_synced_at                 :datetime
#  license                        :string
#  logo_url                       :string
#  maintenance_stats_refreshed_at :datetime
#  mirror_url                     :string
#  name                           :string
#  open_issues_count              :integer
#  private                        :boolean
#  pull_requests_enabled          :string
#  pushed_at                      :datetime
#  rank                           :integer
#  scm                            :string
#  size                           :integer
#  source_name                    :string
#  stargazers_count               :integer
#  status                         :string
#  subscribers_count              :integer
#  uuid                           :string
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  repository_organisation_id     :integer
#  repository_user_id             :integer
#
# Indexes
#
#  github_repositories_lower_language                      (lower((language)::text))
#  index_repositories_on_fork                              (fork)
#  index_repositories_on_host_type_and_uuid                (host_type,uuid) UNIQUE
#  index_repositories_on_lower_host_type_lower_full_name   (lower((host_type)::text), lower((full_name)::text)) UNIQUE
#  index_repositories_on_maintenance_stats_refreshed_at    (maintenance_stats_refreshed_at)
#  index_repositories_on_private                           (private)
#  index_repositories_on_rank_and_stargazers_count_and_id  (rank,stargazers_count,id)
#  index_repositories_on_repository_organisation_id        (repository_organisation_id)
#  index_repositories_on_repository_user_id                (repository_user_id)
#  index_repositories_on_source_name                       (source_name)
#  index_repositories_on_status                            (status)
#
class Repository < ApplicationRecord
  include RepoSearch
  include Status
  include RepoManifests
  include RepositorySourceRank

  # eager load this module to avoid clashing with Gitlab gem in development
  RepositoryHost::Gitlab # rubocop: disable Lint/Void

  STATUSES = ["Active", "Deprecated", "Unmaintained", "Help Wanted", "Removed"].freeze

  API_FIELDS = %i[full_name description fork created_at updated_at pushed_at homepage
                  size stargazers_count language has_issues has_wiki has_pages
                  forks_count mirror_url open_issues_count default_branch
                  subscribers_count private logo_url pull_requests_enabled scm keywords status].freeze

  has_many :projects
  has_many :contributions, dependent: :delete_all
  has_many :contributors, through: :contributions, source: :repository_user
  has_many :tags, dependent: :delete_all
  has_many :published_tags, -> { published }, anonymous_class: Tag
  has_many :manifests, dependent: :destroy
  has_many :repository_dependencies
  has_many :repository_maintenance_stats, dependent: :destroy
  has_many :dependencies, through: :manifests, source: :repository_dependencies
  has_many :dependency_projects, -> { group("projects.id").order(Arel.sql("COUNT(projects.id) DESC")) }, through: :dependencies, source: :project
  has_many :dependency_repos, -> { group("repositories.id") }, through: :dependency_projects, source: :repository

  has_many :repository_subscriptions, dependent: :delete_all
  has_many :web_hooks, dependent: :delete_all
  has_one :readme, dependent: :delete
  belongs_to :repository_organisation
  belongs_to :repository_user
  belongs_to :source, primary_key: :full_name, foreign_key: :source_name, anonymous_class: Repository
  has_many :forked_repositories, primary_key: :full_name, foreign_key: :source_name, anonymous_class: Repository

  validates :full_name, uniqueness: { scope: :host_type }, if: -> { full_name_changed? }
  validates :uuid, uniqueness: { scope: :host_type }, if: -> { uuid_changed? }

  before_save  :normalize_license_and_language
  after_commit :update_all_info_async, on: :create
  after_commit :save_projects, on: :update
  after_commit :update_source_rank_async, on: [:update]

  scope :without_readme, -> { where("repositories.id NOT IN (SELECT repository_id FROM readmes)") }
  scope :with_projects, -> { joins(:projects) }
  scope :without_projects, -> { includes(:projects).where(projects: { repository_id: nil }) }
  scope :with_tags, -> { joins(:tags) }
  scope :without_tags, -> { includes(:tags).where(tags: { repository_id: nil }) }

  scope :host, ->(host_type) { where("lower(repositories.host_type) = ?", host_type.try(:downcase)) }

  scope :fork, -> { where(fork: true) }
  scope :source, -> { where(fork: false) }

  scope :open_source, -> { where(private: false) }
  scope :from_org, ->(org_id) { where(repository_organisation_id: org_id) }

  scope :with_manifests, -> { joins(:manifests) }
  scope :without_manifests, -> { includes(:manifests).where(manifests: { repository_id: nil }) }

  scope :with_description, -> { where("repositories.description <> ''") }
  scope :with_license, -> { where("repositories.license <> ''") }
  scope :without_license, -> { where("repositories.license IS ? OR repositories.license = ''", nil) }

  scope :pushed, -> { where.not(pushed_at: nil) }
  scope :good_quality, -> { maintained.open_source.pushed }
  scope :with_stars, -> { where("repositories.stargazers_count > 0") }
  scope :interesting, -> { with_stars.order(Arel.sql("repositories.stargazers_count DESC, repositories.rank DESC NULLS LAST, repositories.pushed_at DESC")) }
  scope :uninteresting, -> { without_readme.without_manifests.without_license.where("repositories.stargazers_count = 0").where("repositories.forks_count = 0") }

  scope :recently_created, -> { where("created_at > ?", 7.days.ago) }
  scope :hacker_news, -> { order(Arel.sql("((stargazers_count-1)/POW((EXTRACT(EPOCH FROM current_timestamp-created_at)/3600)+2,1.8)) DESC")) }
  scope :trending, -> { good_quality.recently_created.with_stars }

  scope :maintained, -> { where('repositories."status" not in (?) OR repositories."status" IS NULL', %w[Deprecated Removed Unmaintained Hidden]) }
  scope :deprecated, -> { where('repositories."status" = ?', "Deprecated") }
  scope :not_removed, -> { where('repositories."status" not in (?) OR repositories."status" IS NULL', %w[Removed Hidden]) }
  scope :removed, -> { where('repositories."status" = ?', "Removed") }
  scope :unmaintained, -> { where('repositories."status" = ?', "Unmaintained") }
  scope :hidden, -> { where('repositories."status" = ?', "Hidden") }

  scope :indexable, -> { open_source.source.not_removed }

  scope :least_recently_updated_stats, -> { where.not(maintenance_stats_refreshed_at: nil).order(maintenance_stats_refreshed_at: :asc) }
  scope :no_existing_stats, -> { where.missing(:repository_maintenance_stats).where(maintenance_stats_refreshed_at: nil) }

  delegate :download_owner, :download_readme, :domain, :watchers_url, :forks_url,
           :download_fork_source, :download_tags, :download_contributions, :url,
           :create_webhook, :download_forks, :stargazers_url,
           :formatted_host, :get_file_list, :get_file_contents, :issues_url,
           :source_url, :contributors_url, :blob_url, :raw_url, :commits_url,
           :compare_url, :retrieve_commits, :gather_maintenance_stats, to: :repository_host

  def self.language(language)
    where("lower(repositories.language) = ?", language.try(:downcase))
  end

  def meta_tags
    {
      title: "#{full_name} on #{formatted_host}",
      description: description_with_language,
      image: avatar_url(200),
    }
  end

  def description_with_language
    language_text = [language, "repository"].compact.join(" ").with_indefinite_article
    [description, "#{language_text} on #{formatted_host}"].compact.join(" - ")
  end

  def normalize_license_and_language
    self.language = Linguist::Language[language].to_s
    self.language = nil if language.blank?
    return if license.blank?

    if license.downcase == "other"
      self.license = "Other"
    else
      l = Spdx.find(license).try(:id)
      l = "Other" if l.blank?
      self.license = l
    end
  end

  def deprecate!
    update_attribute(:status, "Deprecated")
    projects.each do |project|
      project.update_attribute(:status, "Deprecated")
    end
  end

  def unmaintain!
    update_attribute(:status, "Unmaintained")
    projects.each do |project|
      project.update_attribute(:status, "Unmaintained")
    end
  end

  def save_projects
    projects.find_each(&:forced_save) if previous_changes.any?
  end

  def owner
    repository_organisation_id.present? ? repository_organisation : repository_user
  end

  def to_s
    full_name
  end

  def to_param
    {
      host_type: host_type.downcase,
      owner: owner_name,
      name: project_name,
    }
  end

  def owner_name
    full_name.split("/")[0]
  end

  def project_name
    full_name.split("/")[1]
  end

  def color
    Linguist::Language[language].try(:color)
  end

  def stars
    stargazers_count || 0
  end

  def forks
    forks_count || 0
  end

  def avatar_url(size = 60)
    avatar = repository_host.avatar_url(size)
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
    if host_type == "GitHub"
      uuid || full_name
    else
      full_name
    end
  end

  def recently_synced?
    last_synced_at && last_synced_at > 1.day.ago
  end

  def manual_sync(token = nil)
    update_all_info_async(token)
    self.last_synced_at = Time.zone.now
    save
  end

  def update_all_info_async(token = nil)
    RepositoryDownloadWorker.perform_async(id, token)
  end

  def update_all_info(token = nil)
    token ||= AuthToken.token if host_type == "GitHub"
    check_status
    return if status == "Removed"

    update_from_repository(token)
    unless last_synced_at && last_synced_at > 2.minutes.ago
      download_owner
      download_fork_source(token)
      download_readme(token)
      download_tags(token)
      download_contributions(token)
      download_manifests(token)
      update_source_rank(force: true)
    end
    update(last_synced_at: Time.now)
  end

  def update_from_repository(token)
    repository_host.update_from_host(token)
  end

  def self.create_from_host(host_type, full_name, token = nil)
    RepositoryHost.const_get(host_type.capitalize).create(full_name, token)
  end

  def self.create_from_hash(repo_hash)
    return unless repo_hash

    repo_hash = repo_hash.to_hash.with_indifferent_access

    ActiveRecord::Base.transaction do
      g = Repository.where(host_type: (repo_hash[:host_type] || "GitHub")).find_by(uuid: repo_hash[:id])
      g = Repository.host(repo_hash[:host_type] || "GitHub").find_by("lower(full_name) = ?", repo_hash[:full_name].downcase) if g.nil?
      g = Repository.new(uuid: repo_hash[:id], full_name: repo_hash[:full_name]) if g.nil?
      g.host_type = repo_hash[:host_type] || "GitHub"
      g.full_name = repo_hash[:full_name] if g.full_name.downcase != repo_hash[:full_name].downcase
      g.uuid = repo_hash[:id] if g.uuid.nil?
      g.license = repo_hash[:license][:key] if repo_hash[:license]
      g.source_name = (repo_hash[:parent][:full_name] if repo_hash[:fork] && repo_hash[:parent])

      g.assign_attributes repo_hash.slice(*Repository::API_FIELDS)

      if g.changed?
        g.save ? g : nil
      else
        g
      end
    end
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  def check_status
    Repository.check_status(host_type, full_name)
  end

  def self.check_status(host_type, repo_full_name)
    domain = RepositoryHost::Base.domain(host_type)
    response = Typhoeus.head("#{domain}/#{repo_full_name}")

    if response.response_code == 404
      repo = Repository.includes(:projects).find_by_full_name(repo_full_name)
      if repo
        repo.update_attribute(:status, "Removed") unless repo.private?
        repo.projects.each do |project|
          next unless %w[bower go elm alcatraz julia nimble].include?(project.platform.downcase)

          project.update_attribute(:status, "Removed")
        end
      end
    end
  end

  def self.update_from_hook(uuid, sender_id)
    repository = Repository.where(host_type: "GitHub").find_by_uuid(uuid)
    user = Identity.where("provider ILIKE ?", "github%").where(uid: sender_id).first.try(:user)
    if user.present? && repository.present?
      repository.download_manifests(user.token)
      repository.update_all_info_async(user.token)
    end
  end

  def self.update_from_star(repo_name)
    repository = Repository.host("GitHub").find_by_full_name(repo_name)
    if repository
      repository.increment!(:stargazers_count)
    else
      CreateRepositoryWorker.perform_async("GitHub", repo_name)
    end
  end

  def self.update_from_tag(repo_name)
    repository = Repository.host("GitHub").find_by_full_name(repo_name)
    if repository
      repository.download_tags
    else
      CreateRepositoryWorker.perform_async("GitHub", repo_name)
    end
  end

  def github_contributions_count
    contributions_count # legacy alias
  end

  def github_id
    uuid # legacy alias
  end

  def sorted_tags
    @sorted_tags ||= tags.sort
  end

  def repository_host
    @repository_host ||= RepositoryHost.const_get(host_type.capitalize).new(self)
  end

  def hide
    update!(status: "Hidden")
  end

  def gather_maintenance_stats_async(priority: :medium)
    RepositoryMaintenanceStatWorker.enqueue(id, priority: priority)
  end
end
