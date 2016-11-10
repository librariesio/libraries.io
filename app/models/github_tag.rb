class GithubTag < ApplicationRecord
  belongs_to :github_repository#, touch: true
  validates_presence_of :name, :sha, :github_repository

  scope :published, -> { where('published_at IS NOT NULL') }

  after_commit :send_notifications_async, on: :create

  def to_s
    name
  end

  def update_github_repo_async
    GithubDownloadWorker.perform_async(github_repository_id)
  end

  def send_notifications_async
    return if published_at && published_at < 1.week.ago
    TagNotificationsWorker.perform_async(self.id) if has_projects?
  end

  def send_notifications
    if has_projects?
      notify_subscribers
      notify_firehose
      notify_web_hooks
    end
  end

  def notify_web_hooks
    github_repository.projects.without_versions.each do |project|
      repos = project.subscriptions.map(&:github_repository).compact.uniq
      repos.each do |repo|
        requirements = repo.repository_dependencies.select{|rd| rd.project == project }.map(&:requirements)
        repo.web_hooks.each do |web_hook|
          web_hook.send_new_version(project, project.platform, self, requirements)
        end
      end
    end
  end

  def has_projects?
    github_repository && github_repository.projects.without_versions.length > 0
  end

  def notify_subscribers
    github_repository.projects.without_versions.each do |project|
      subscriptions = project.subscriptions
      subscriptions = subscriptions.include_prereleases if prerelease?

      subscriptions.group_by(&:notification_user).each do |user, user_subscriptions|
        next if user.nil?
        next if user.muted?(project)
        next if !user.emails_enabled?
        VersionsMailer.new_version(user, project, self).deliver_later
      end
    end
  end

  def notify_firehose
    github_repository.projects.without_versions.each do |project|
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

  def parsed_number
    @parsed_number ||= semantic_version || number
  end

  def clean_number
    @clean_number ||= (SemanticRange.clean(number) || number)
  end

  def semantic_version
    @semantic_version ||= begin
      Semantic::Version.new(clean_number)
    rescue ArgumentError
      nil
    end
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

  def follows_semver?
    @follows_semver ||= valid_number?
  end

  def number
    name
  end

  def greater_than_1?
    return nil unless follows_semver?
    begin
      SemanticRange.gte(clean_number, '1.0.0')
    rescue
      false
    end
  end

  def github_url
    "#{github_repository.url}/releases/tag/#{name}"
  end
end
