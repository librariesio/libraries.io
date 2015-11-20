class Version < ActiveRecord::Base
  validates_presence_of :project_id, :number
  validates_uniqueness_of :number, scope: :project_id

  belongs_to :project, touch: true
  counter_culture :project
  has_many :dependencies, dependent: :destroy

  after_commit :send_notifications_async, on: :create

  scope :newest_first, -> { order('versions.published_at DESC') }

  def as_json(options = nil)
    super({ only: [:number, :published_at] }.merge(options || {}))
  end

  def notify_subscribers
    project.subscriptions.group_by(&:notification_user).each do |user, subscriptions|
      next if user.nil?
      next if user.muted?(project)
      VersionsMailer.new_version(user, project, self).deliver_later
    end
  end

  def notify_firehose
    Firehose.new_version(project, project.platform, self)
  end

  def notify_web_hooks
    repos = project.subscriptions.map(&:github_repository).compact
    repos.each do |repo|
      repo.web_hooks.each do |web_hook|
        web_hook.send_new_version(project, project.platform, self)
      end
    end
  end

  def send_notifications_async
    return if published_at && published_at < 1.week.ago
    VersionNotificationsWorker.perform_async(self.id)
  end

  def send_notifications
    notify_subscribers
    notify_firehose
    notify_web_hooks
  end

  def published_at
    read_attribute(:published_at).presence || created_at
  end

  def <=>(other)
    if parsed_number.is_a?(String) || other.parsed_number.is_a?(String)
      other.published_at <=> published_at
    else
      other.parsed_number <=> parsed_number
    end
  end

  def parsed_number
    semantic_version || number
  end

  def semantic_version
    Semantic::Version.new(number) rescue nil
  end

  def stable?
    !prerelease?
  end

  def prerelease?
    !!parsed_number.try(:pre)
  end

  def valid_number?
    !!semantic_version
  end

  def follows_semver_for_dependency_requirements?
    dependencies.all?(&:valid_requirements?)
  end

  def follows_semver?
    valid_number? && follows_semver_for_dependency_requirements?
  end

  def any_outdated_dependencies?
    dependencies.any?(&:outdated?)
  end

  def greater_than_1?
    return nil unless follows_semver?
    begin
      SemanticRange.gte(number, '1.0.0')
    rescue
      false
    end
  end

  def to_param
    project.to_param.merge(number: number)
  end

  def to_s
    number
  end
end
