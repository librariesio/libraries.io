class Dependency < ActiveRecord::Base
  belongs_to :version
  belongs_to :project, touch: true

  validates_presence_of :project_name, :version_id, :requirements, :platform

  scope :without_project_id, -> { where(project_id: nil) }

  def find_project_id
    Project.platform(platform).where('lower(name) = ?', project_name.downcase).first.try(:id)
  end

  def update_project_id
    proj_id = find_project_id
    update_attribute(:project_id, proj_id) if proj_id.present?
  end
end
