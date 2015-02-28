class Version < ActiveRecord::Base
  validates_presence_of :project_id, :number
  # validate unique number and project_id
  belongs_to :project, touch: true
  counter_culture :project
  has_many :dependencies

  after_create :notify_subscribers

  def notify_subscribers
    project.subscriptions.each do |subscription|
      VersionMailer.new_version(subscription.user, self).deliver_later
    end
  end

  def <=>(other)
    if parsed_number.is_a?(String) || other.parsed_number.is_a?(String)
      other.number <=> number
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
