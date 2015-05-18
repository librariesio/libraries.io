class RepositoryDependency < ActiveRecord::Base
  belongs_to :manifest
  belongs_to :project

  scope :with_project, -> { joins(:project).where('projects.id IS NOT NULL') }
end
