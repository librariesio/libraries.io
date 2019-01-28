class ProjectUpdatePriority < ApplicationRecord
  belongs_to :project
  enum priority: [ :low, :medium, :high ]

  def self.low_priority_date
    1.month.ago
  end

  def self.medium_priority_date
    2.weeks.ago
  end

  def self.high_priority_date
    1.week.ago
  end
end
