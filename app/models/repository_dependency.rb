class RepositoryDependency < ActiveRecord::Base
  belongs_to :manifest
  belongs_to :project

  scope :with_project, -> { joins(:project).where('projects.id IS NOT NULL') }
  scope :without_project_id, -> { where(project_id: nil) }

  def find_project_id
    Project.platform(platform).where('lower(name) = ?', project_name.try(:downcase)).first.try(:id)
  end

  def update_project_id
    proj_id = find_project_id
    update_attribute(:project_id, proj_id) if proj_id.present?
  end
end
