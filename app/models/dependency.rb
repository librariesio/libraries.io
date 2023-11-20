# frozen_string_literal: true

# == Schema Information
#
# Table name: dependencies
#
#  id           :integer          not null, primary key
#  kind         :string
#  optional     :boolean          default(FALSE)
#  platform     :string
#  project_name :string
#  requirements :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  project_id   :integer
#  version_id   :integer
#
# Indexes
#
#  index_dependencies_on_project_created_at_date  (project_id, ((created_at)::date))
#  index_dependencies_on_project_id               (project_id)
#  index_dependencies_on_version_id               (version_id)
#
class Dependency < ApplicationRecord
  include DependencyChecks

  belongs_to :version
  belongs_to :project

  validates_presence_of :project_name, :version_id, :requirements, :platform

  scope :with_project, -> { joins(:project).where("projects.id IS NOT NULL") }
  scope :without_project_id, -> { where(project_id: nil) }
  scope :with_project_name, -> { where("dependencies.project_name <> ''") }
  scope :kind, ->(kind) { where(kind: kind) }
  scope :platform, ->(platform) { where("lower(dependencies.platform) = ?", platform.try(:downcase)) }

  before_create :set_project_id

  alias_attribute :name, :project_name
  alias_attribute :latest_stable, :latest_stable_release_number
  alias_attribute :latest, :latest_release_number
  alias_attribute :deprecated, :deprecated?
  alias outdated outdated?

  delegate :latest_stable_release_number, :latest_release_number, :deprecated?, :score, to: :project, allow_nil: true

  def filepath
    nil
  end

  def find_project_id
    Project.find_best(platform, project_name.strip)&.id
  end

  def compatible_license?
    return nil unless project
    return nil if project.normalized_licenses.empty?
    return nil if version.project.normalized_licenses.empty?

    project.normalized_licenses.any? do |license|
      version.project.normalized_licenses.any? do |other_license|
        License::Compatibility.forward_compatibility(license, other_license)
      rescue StandardError
        true
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
