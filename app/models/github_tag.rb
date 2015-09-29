class GithubTag < ActiveRecord::Base
  belongs_to :github_repository, touch: true
  validates_presence_of :name, :sha, :github_repository

  scope :published, -> { where('published_at IS NOT NULL') }

  after_commit :send_notifications_async, on: :create

  def to_s
    name
  end

  def send_notifications_async
    TagNotificationsWorker.perform_async(self.id) if has_projects?
  end

  def send_notifications
    if has_projects?
      notify_subscribers
      notify_firehose
    end
  end

  def has_projects?
    github_repository && github_repository.projects.without_versions.length > 0
  end

  def notify_subscribers
    github_repository.projects.without_versions.each do |project|
      project.subscriptions.group_by(&:notification_user).each do |user, subscriptions|
        next if user.nil?
        next if user.muted?(project)
        VersionsMailer.new_version(user, project, self).deliver_later
      end
    end
  end

  def notify_firehose
    github_repository.projects.without_versions.each do |project|
      Firehose.new_version(project, project.platform, number)
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

  def number
    name
  end

  def github_url
    "#{github_repository.url}/releases/tag/#{name}"
  end
end
