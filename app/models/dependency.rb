class Dependency < ActiveRecord::Base
  belongs_to :version
  belongs_to :project

  validates_presence_of :project_name, :version_id, :requirements, :platform

  def find_project_id
    Project.platform(version.project.platform).where('lower(name) = ?', project_name.downcase).first.try(:id)
  end
end
