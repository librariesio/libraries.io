class ProjectUpdatePriority < ApplicationRecord
  belongs_to :project
  enum priority: { low: 0, medium: 1, high: 2 }

  after_commit :enqueue_high_priority

  def self.low_priority_date
    1.month.ago
  end

  def self.medium_priority_date
    2.weeks.ago
  end

  def self.high_priority_date
    1.week.ago
  end

  def enqueue_high_priority
    return unless high?
    project.update_maintenance_stats_async(priority: :high) if project.repository_maintenance_stats.length == 0
  end
end
