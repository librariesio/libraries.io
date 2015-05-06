class Version < ActiveRecord::Base
  validates_presence_of :project_id, :number
  # validate unique number and project_id
  belongs_to :project, touch: true
  counter_culture :project
  has_many :dependencies

  after_commit :notify_subscribers, :notify_gitter, :notify_firehose, on: :create

  def notify_subscribers
    project.subscriptions.each do |subscription|
      VersionsMailer.new_version(subscription.notification_user, project, self).deliver_later
    end
  end

  def notify_gitter
    GitterNotifications.new_version(project.name, project.platform, number)
  end

  def notify_firehose
    Firehose.new_version(project.name, project.platform, number)
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
