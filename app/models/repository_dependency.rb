# frozen_string_literal: true

class RepositoryDependency < ApplicationRecord
  include DependencyChecks

  belongs_to :manifest
  belongs_to :project
  belongs_to :repository

  scope :with_project, -> { joins(:project).where("projects.id IS NOT NULL") }
  scope :without_project_id, -> { where(project_id: nil) }
  scope :with_project_name, -> { where("repository_dependencies.project_name <> ''") }
  scope :platform, ->(platform) { where("lower(repository_dependencies.platform) = ?", platform.try(:downcase)) }
  scope :kind, ->(kind) { where(kind: kind) }

  before_create :set_project_id

  alias_attribute :name, :project_name
  alias_attribute :latest_stable, :latest_stable_release_number
  alias_attribute :latest, :latest_release_number
  alias_attribute :deprecated, :is_deprecated?
  alias outdated outdated?

  delegate :latest_stable_release_number, :latest_release_number, :is_deprecated?, to: :project, allow_nil: true
  delegate :filepath, to: :manifest

  def find_project_id
    Project.find_best(platform, project_name&.strip)&.id
  end

  def compatible_license?
    return nil unless project
    return nil if project.normalized_licenses.empty?
    return nil if repository.license.blank?

    project.normalized_licenses.any? do |license|
      License::Compatibility.forward_compatibility(license, repository.license)
    rescue StandardError
      true
    end
  end

  def set_project_id
    self.project_id = find_project_id unless project_id.present?
  end

  def update_project_id
    proj_id = find_project_id
    update_attribute(:project_id, proj_id) if proj_id.present?
  end

  def project_name
    read_attribute(:project_name).try(:tr, " \n\t\r", "")
  end
end
