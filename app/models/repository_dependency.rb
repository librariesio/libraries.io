class RepositoryDependency < ApplicationRecord
  include DependencyChecks

  belongs_to :manifest
  belongs_to :project

  scope :with_project, -> { joins(:project).where('projects.id IS NOT NULL') }
  scope :without_project_id, -> { where(project_id: nil) }
  scope :with_project_name, -> { where("repository_dependencies.project_name <> ''") }
  scope :platform, ->(platform) { where('lower(repository_dependencies.platform) = ?', platform.try(:downcase)) }
  scope :kind, ->(kind) { where(kind: kind) }

  before_create :set_project_id

  alias_attribute :name, :project_name
  alias_attribute :latest_stable, :latest_stable_release_number
  alias_attribute :latest, :latest_release_number
  alias_attribute :deprecated, :is_deprecated?
  alias_method :outdated, :outdated?

  delegate :latest_stable_release_number, :latest_release_number, :is_deprecated?, to: :project, allow_nil: true
  delegate :filepath, to: :manifest

  def repository
    manifest.try(:repository)
  end

  def find_project_id
    project_id = Project.platform(platform).where(name: project_name.try(:strip)).limit(1).pluck(:id).first
    return project_id if project_id
    Project.lower_platform(platform).lower_name(project_name.try(:strip)).limit(1).pluck(:id).first
  end

  def compatible_license?
    return nil unless project
    return nil if project.normalized_licenses.empty?
    return nil if manifest.repository.license.blank?
    project.normalized_licenses.any? do |license|
      begin
        License::Compatibility.forward_compatibility(license, manifest.repository.license)
      rescue
        true
      end
    end
  end

  def set_project_id
    self.project_id = find_project_id
  end

  def update_project_id
    proj_id = find_project_id
    update_attribute(:project_id, proj_id) if proj_id.present?
  end

  def project_name
    read_attribute(:project_name).try(:tr, " \n\t\r", '')
  end
end
