class Version < ApplicationRecord
  include Releaseable

  validates_presence_of :project_id, :number
  validates_uniqueness_of :number, scope: :project_id

  belongs_to :project
  counter_culture :project
  has_many :dependencies, dependent: :delete_all

  after_commit :send_notifications_async, on: :create
  after_commit :update_repository_async, on: :create
  after_commit :save_project, on: :create

  scope :newest_first, -> { order('versions.published_at DESC') }

  def as_json(options = nil)
    super({ only: [:number, :published_at] }.merge(options || {}))
  end

  def save_project
    project.try(:forced_save)
    project.try(:update_repository_async)
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
      next if !user.emails_enabled?
      VersionsMailer.new_version(user, project, self).deliver_later

      next if user.slack_api_token?
      next if user.slack_channel?
      requirements = repo.repository_dependencies.select{|rd| rd.project == project }.map(&:requirements)
        post_to_slack(project, project.platform, self, requirements, user.slack_api_token, user.slack_channel)

    end
  end

  def notify_firehose
    Firehose.new_version(project, project.platform, self)
  end

  def notify_web_hooks
    repos = project.subscriptions.map(&:repository).compact.uniq
    repos.each do |repo|
      requirements = repo.repository_dependencies.select{|rd| rd.project == project }.map(&:requirements)
      repo.web_hooks.each do |web_hook|
        web_hook.send_new_version(project, project.platform, self, requirements)
      end
    end
  end


  def post_to_slack(repository, platform, name, version, requiremnts, token, channel)
    return if ENV['SKIP_PRERELEASE'] && prerelease?(platform, version)
    return if satisfied_by_requirements?(requiremnts, version, platform)

    text = "There's a newer version of #{name} that #{repository} depends on.
More info: https://libraries.io/#{platform.downcase}/#{name}/#{version}"

    client = Slack::Web::Client.new(token)
    client.chat_postMessage(channel: channel, text: text, as_user: true)
  end

  def satisfied_by_requirements?(requiremnts, version, platform = nil)
    return false if requiremnts.nil? || requiremnts.empty?
    requiremnts.none? do |requirement|
      SemanticRange.gtr(version, requirement, false, platform)
    end
  rescue
    false
  end

  def prerelease?(platform, version)
    parsed_version = SemanticRange.parse(version) rescue nil
    return true if parsed_version && parsed_version.prerelease.length > 0
    if platform.downcase == 'rubygems'
      !!(version =~ /[a-zA-Z]/)
    else
      false
    end
  end

  def send_notifications_async
    return if published_at && published_at < 1.week.ago
    VersionNotificationsWorker.perform_async(self.id)
  end

  def update_repository_async
    return unless project.repository_id.present?
    RepositoryDownloadWorker.perform_async(project.repository_id)
  end

  def send_notifications
    project.try(:repository).try(:download_tags) rescue nil
    notify_subscribers
    notify_firehose
    notify_web_hooks
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
    if semantic_version
      !!semantic_version.pre
    elsif platform.try(:downcase) == 'rubygems'
      !!(number =~ /[a-zA-Z]/)
    else
      false
    end
  end

  def any_outdated_dependencies?
    @any_outdated_dependencies ||= dependencies.kind('runtime').any?(&:outdated?)
  end

  def to_param
    project.to_param.merge(number: number)
  end

  def load_dependencies_tree(kind, date = nil)
    TreeResolver.new(self, kind, date).load_dependencies_tree
  end

  def related_tag
    return nil unless project && project.repository
    @related_tag ||= project.repository.tags.find{|t| t.clean_number == clean_number }
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
    return nil unless project && project.repository && related_tag && previous_version && previous_version.related_tag
    project.repository.compare_url(previous_version.related_tag.number, related_tag.number)
  end
end
