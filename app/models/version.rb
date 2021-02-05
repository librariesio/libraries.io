# frozen_string_literal: true

class Version < ApplicationRecord
  include Releaseable

  STATUSES = %w[Deprecated Removed].freeze

  validates :project_id, :number, presence: true
  validates :number, uniqueness: { scope: :project_id }
  validates :status, inclusion: { in: STATUSES, allow_blank: true }

  belongs_to :project
  counter_culture :project
  has_many :dependencies, dependent: :delete_all
  has_many :runtime_dependencies, -> { where kind: %w[runtime normal] }, class_name: "Dependency"

  before_save :update_spdx_expression
  after_create_commit :send_notifications_async,
                      :update_repository_async,
                      :save_project,
                      :log_version_creation

  scope :newest_first, -> { order("versions.published_at DESC") }

  def save_project
    project.try(:forced_save)
    project.try(:update_repository_async)
  end

  def update_spdx_expression
    if original_license.is_a?(String)
      self.spdx_expression = handle_string_spdx_expression(original_license)
    elsif original_license.is_a?(Array)
      possible_license = original_license.join(" AND ")
      self.spdx_expression = handle_string_spdx_expression(possible_license)
    end
  end

  def handle_string_spdx_expression(license_string)
    if license_string == ""
      "NONE"
    elsif Spdx.valid_spdx?(license_string)
      license_string
    else
      "NOASSERTION"
    end
  end

  def platform
    project.try(:platform)
  end

  def notify_subscribers
    subscriptions = project.subscriptions
    subscriptions = subscriptions.include_prereleases if prerelease?

    subscriptions.group_by(&:notification_user).each do |user, _user_subscriptions|
      next if user.nil?
      next if user.muted?(project)
      next unless user.emails_enabled?

      VersionsMailer.new_version(user, project, self).deliver_later
    end
  end

  def notify_firehose
    Firehose.new_version(project, project.platform, self)
  end

  def notify_web_hooks
    repos = project.subscriptions.map(&:repository).compact.uniq
    repos.each do |repo|
      requirements = repo.repository_dependencies.select { |rd| rd.project == project }.map(&:requirements)
      repo.web_hooks.each do |web_hook|
        web_hook.send_new_version(project, project.platform, self, requirements)
      end
    end
  end

  def send_notifications_async
    return if published_at && published_at < 1.week.ago

    VersionNotificationsWorker.perform_async(id)
  end

  def update_repository_async
    return unless project.repository_id.present?

    RepositoryDownloadWorker.perform_async(project.repository_id)
  end

  def send_notifications
    dt = ns = nf = nw = nil

    overall = Benchmark.measure do
      dt = Benchmark.measure do
        project.try(:repository).try(:download_tags)
      rescue StandardError
        nil
      end

      ns = Benchmark.measure { notify_subscribers }
      nf = Benchmark.measure { notify_firehose }
      nw = Benchmark.measure { notify_web_hooks }
    end

    Rails.logger.info("Version#send_notifications benchmark overall: #{overall.real * 1000}ms dt:#{dt.real * 1000}ms ns:#{ns.real * 1000}ms nf:#{nf.real * 1000}ms nw:#{nw.real * 1000}ms v_id:#{id}")
  end

  def log_version_creation
    lag = (created_at - published_at).round
    Rails.logger.info("[NEW VERSION] platform=#{platform&.downcase || 'unknown'} name=#{project&.name} version=#{number} lag=#{lag}")
  end

  def published_at
    @published_at ||= read_attribute(:published_at).presence || created_at
  end

  def <=>(other)
    if parsed_number.is_a?(String) || other.parsed_number.is_a?(String)
      other.published_at <=> published_at
    else
      other.parsed_number <=> parsed_number
    end
  end

  def prerelease?
    if semantic_version && semantic_version.pre.present?
      true
    elsif platform.try(:downcase) == "rubygems"
      number.count("a-zA-Z") > 0
    else
      false
    end
  end

  def any_outdated_dependencies?
    @any_outdated_dependencies ||= runtime_dependencies.any?(&:outdated?)
  end

  def to_param
    project.to_param.merge(number: number)
  end

  def load_dependencies_tree(kind, date = nil)
    TreeResolver.new(self, kind, date).load_dependencies_tree
  end

  def related_tag
    return nil unless project&.repository

    @related_tag ||= project.repository.tags.find { |t| t.clean_number == clean_number }
  end

  def repository_url
    related_tag.try(:repository_url)
  end

  def related_versions
    @related_versions ||= project.try(:versions).try(:sort)
  end

  def related_versions_with_tags
    @related_versions_with_tags ||= related_versions.select(&:related_tag)
  end

  def version_index
    related_versions_with_tags.index(self)
  end

  def next_version
    related_versions_with_tags[version_index - 1]
  end

  def previous_version
    related_versions_with_tags[version_index + 1]
  end

  def diff_url
    return nil unless project&.repository && related_tag && previous_version && previous_version.related_tag

    project.repository.compare_url(previous_version.related_tag.number, related_tag.number)
  end

  def set_runtime_dependencies_count
    update_column(:runtime_dependencies_count, runtime_dependencies.count)
  end
end
