class Tag < ApplicationRecord
  include Releaseable

  belongs_to :repository, touch: true
  validates_presence_of :name, :sha, :repository
  validates_uniqueness_of :name, scope: :repository_id

  scope :published, -> { where('published_at IS NOT NULL') }

  after_commit :send_notifications_async, on: :create
  after_commit :save_projects

  def save_projects
    repository.try(:save_projects)
  end

  def send_notifications_async
    return if published_at && published_at < 1.week.ago
    TagNotificationsWorker.perform_async(self.id) if has_projects?
  end

  def send_notifications
    if has_projects?
      repository.download_tags rescue nil
      notify_subscribers
      notify_firehose
      notify_web_hooks
    end
  end

  def notify_web_hooks
    repository.projects.without_versions.each do |project|
      repos = project.subscriptions.map(&:repository).compact.uniq
      repos.each do |repo|
        requirements = repo.repository_dependencies.select{|rd| rd.project == project }.map(&:requirements)
        repo.web_hooks.each do |web_hook|
          web_hook.send_new_version(project, project.platform, self, requirements)
        end
      end
    end
  end

  def has_projects?
    repository && repository.projects.without_versions.length > 0
  end

  def notify_subscribers
    repository.projects.without_versions.each do |project|
      subscriptions = project.subscriptions
      subscriptions = subscriptions.include_prereleases if prerelease?

      subscriptions.group_by(&:notification_user).each do |user, _user_subscriptions|
        next if user.nil?
        next if user.muted?(project)
        next if !user.emails_enabled?
        VersionsMailer.new_version(user, project, self).deliver_later
      end
    end
  end

  def notify_firehose
    repository.projects.without_versions.each do |project|
      Firehose.new_version(project, project.platform, self)
    end
  end

  def <=>(other)
    if parsed_number.is_a?(String) || other.parsed_number.is_a?(String)
      other.number <=> number
    else
      other.parsed_number <=> parsed_number
    end
  end

  def prerelease?
    !!parsed_number.try(:pre)
  end

  def number
    name
  end

  def repository_url
    case repository.host_type
    when 'GitHub'
      "#{repository.url}/releases/tag/#{name}"
    when 'GitLab'
      "#{repository.url}/tags/#{name}"
    when 'Bitbucket'
      "#{repository.url}/commits/tag/#{name}"
    end
  end

  def related_tags
    repository.sorted_tags
  end

  def tag_index
    related_tags.index(self)
  end

  def next_tag
    related_tags[tag_index - 1]
  end

  def previous_tag
    related_tags[tag_index + 1]
  end

  alias_method :previous_version, :previous_tag

  def related_tag
    true
  end

  def diff_url
    return nil unless repository && previous_tag && previous_tag
    repository.compare_url(previous_tag.number, number)
  end

  def runtime_dependencies_count
    nil # tags can't have dependencies yet
  end
end
