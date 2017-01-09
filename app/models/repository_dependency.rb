class RepositoryDependency < ApplicationRecord
  include DependencyChecks

  belongs_to :manifest
  belongs_to :project

  scope :with_project, -> { joins(:project).where('projects.id IS NOT NULL') }
  scope :without_project_id, -> { where(project_id: nil) }
  scope :with_project_name, -> { where("repository_dependencies.project_name <> ''") }
  scope :platform, ->(platform) { where('lower(repository_dependencies.platform) = ?', platform.try(:downcase)) }
  scope :kind, ->(kind) { where(kind: kind) }

  after_create :update_project_id

  def github_repository
    manifest.try(:github_repository)
  end

  def find_project_id
    Project.platform(platform).where('lower(name) = ?', project_name.try(:downcase).try(:strip)).limit(1).pluck(:id).first
  end

  def compatible_license?
    return nil unless project
    return nil if project.normalized_licenses.empty?
    return nil if manifest.github_repository.license.blank?
    project.normalized_licenses.any? do |license|
      begin
        License::Compatibility.forward_compatiblity(license, manifest.github_repository.license)
      rescue
        true
      end
    end
  end

  def update_project_id
    proj_id = find_project_id
    update_attribute(:project_id, proj_id) if proj_id.present?
  end

  def project_name
    read_attribute(:project_name).try(:tr, " \n\t\r", '')
  end
end
