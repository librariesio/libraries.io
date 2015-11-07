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

  def send_notifications_async
    return if published_at && published_at < 1.week.ago
    VersionNotificationsWorker.perform_async(self.id)
  end

  def send_notifications
    notify_subscribers
    notify_firehose
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
    Semantic::Version.new(number) rescue number
  end

  def to_param
    project.to_param.merge(number: number)
  end

  def to_s
    number
  end
end
