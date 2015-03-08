class GithubTag < ActiveRecord::Base
  belongs_to :github_repository
  validates_presence_of :name, :sha, :github_repository
  after_create :notify_subscribers

  def to_s
    name
  end

  def notify_subscribers
    github_repository.projects.each do |project|
      project.subscriptions.each do |subscription|
        VersionsMailer.new_version(subscription.user, project, self).deliver_later
      end
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
