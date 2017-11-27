class DependencyActivity < ApplicationRecord
  belongs_to :repository
  belongs_to :project

  def to_partial_path
    'dependencies/activity'
  end
end
