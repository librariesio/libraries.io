class Dependency < ApplicationRecord
  include DependencyChecks

  belongs_to :version
  belongs_to :project

  validates_presence_of :project_name, :version_id, :requirements, :platform

  scope :with_project, -> { joins(:project).where('projects.id IS NOT NULL') }
  scope :without_project_id, -> { where(project_id: nil) }
  scope :with_project_name, -> { where("dependencies.project_name <> ''") }
  scope :kind, ->(kind) { where(kind: kind) }
  scope :platform, ->(platform) { where('lower(dependencies.platform) = ?', platform.try(:downcase)) }

  before_create :set_project_id

  alias_attribute :name, :project_name
  alias_attribute :latest_stable, :latest_stable_release_number
  alias_attribute :latest, :latest_release_number
  alias_attribute :deprecated, :is_deprecated?
  alias_method :outdated, :outdated?

  delegate :latest_stable_release_number, :latest_release_number, :is_deprecated?, :score, to: :project, allow_nil: true

  def filepath
    nil
  end

  def find_project_id
    project_id = Project.platform(platform).where(name: project_name.strip).limit(1).pluck(:id).first
    return project_id if project_id
    Project.lower_platform(platform).lower_name(project_name.strip).limit(1).pluck(:id).first
  end

  def compatible_license?
    return nil unless project
    return nil if project.normalized_licenses.empty?
    return nil if version.project.normalized_licenses.empty?
    project.normalized_licenses.any? do |license|
      version.project.normalized_licenses.any? do |other_license|
        begin
          License::Compatibility.forward_compatibility(license, other_license)
        rescue
          true
        end
      end
    end
  end

  def set_project_id
    self.project_id = find_project_id unless project_id.present?
  end

  def update_project_id
    proj_id = find_project_id
    update_attribute(:project_id, proj_id) if proj_id.present?
  end
end
