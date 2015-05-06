class GithubTag < ActiveRecord::Base
  belongs_to :github_repository
  validates_presence_of :name, :sha, :github_repository

  after_commit :notify_subscribers, :notify_gitter, :notify_firehose, on: :create

  def to_s
    name
  end

  def notify_subscribers
    github_repository.projects.each do |project|
      next if project.versions_count > 0
      project.subscriptions.each do |subscription|
        VersionsMailer.new_version(subscription.notification_user, project, self).deliver_later
      end
    end
  end

  def notify_gitter
    github_repository.projects.each do |project|
      next if project.versions_count > 0
      GitterNotifications.new_version(project.name, project.platform, number)
    end
  end

  def notify_firehose
    github_repository.projects.each do |project|
      next if project.versions_count > 0
      Firehose.new_version(project.name, project.platform, number)
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
