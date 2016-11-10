class Dependency < ApplicationRecord
  include DependencyChecks

  belongs_to :version
  belongs_to :project#, touch: true

  validates_presence_of :project_name, :version_id, :requirements, :platform

  scope :with_project, -> { joins(:project).where('projects.id IS NOT NULL') }
  scope :without_project_id, -> { where(project_id: nil) }
  scope :with_project_name, -> { where("project_name <> ''") }
  scope :kind, ->(kind) { where(kind: kind) }

  after_create :update_project_id

  def find_project_id
    project_id = Project.platform(platform).where(name: project_name.strip).limit(1).pluck(:id).first
    return project_id if project_id
    Project.platform(platform).where('lower(name) = ?', project_name.downcase.strip).limit(1).pluck(:id).first
  end

  def compatible_license?
    return nil unless project
    return nil if project.normalized_licenses.empty?
    return nil if version.project.normalized_licenses.empty?
    project.normalized_licenses.any? do |license|
      version.project.normalized_licenses.any? do |other_license|
        begin
          License::Compatibility.forward_compatiblity(license, other_license)
        rescue
          true
        end
      end
    end
  end

  def update_project_id
    proj_id = find_project_id
    update_attribute(:project_id, proj_id) if proj_id.present?
  end
end
