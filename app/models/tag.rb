# frozen_string_literal: true

# == Schema Information
#
# Table name: tags
#
#  id            :integer          not null, primary key
#  kind          :string
#  name          :string
#  published_at  :datetime
#  sha           :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  repository_id :integer
#
# Indexes
#
#  index_tags_on_repository_id_and_name  (repository_id,name)
#
class Tag < ApplicationRecord
  include Releaseable

  belongs_to :repository, touch: true
  validates_presence_of :name, :sha, :repository
  validates_uniqueness_of :name, scope: :repository_id

  scope :published, -> { where("published_at IS NOT NULL") }

  after_commit :send_notifications_async, on: :create
  after_commit :save_projects

  def save_projects
    repository.try(:save_projects)
  end

  def send_notifications_async
    return if published_at && published_at < 1.week.ago

    TagNotificationsWorker.perform_async(id) if projects?
  end

  def send_notifications
    if projects?
      notify_subscribers
      notify_web_hooks
    end
  end

  def notify_web_hooks
    repository.projects.without_versions.each do |project|
      repos = project.subscriptions.map(&:repository).compact.uniq
      repos.each do |repo|
        requirements = repo.projects_dependencies.includes(:project).select { |rd| rd.project == project }.map(&:requirements)
        repo.web_hooks.each do |web_hook|
          web_hook.send_new_version(project, project.platform, self, requirements)
        end
      end
    end
  end

  def projects?
    repository && !repository.projects.without_versions.empty?
  end

  def notify_subscribers
    repository.projects.without_versions.each do |project|
      project.mailing_list(include_prereleases: prerelease?).each do |user|
        VersionsMailer.new_version(user, project, self).deliver_later
      end
    end
  end

  def <=>(other)
    if parsed_number.is_a?(String) || other.parsed_number.is_a?(String)
      other.number <=> number
    else
      begin
        other.parsed_number <=> parsed_number
      rescue ArgumentError
        other.number <=> number
      end
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
    when "GitHub"
      "#{repository.url}/releases/tag/#{name}"
    when "GitLab"
      "#{repository.url}/tags/#{name}"
    when "Bitbucket"
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

  alias previous_version previous_tag

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
