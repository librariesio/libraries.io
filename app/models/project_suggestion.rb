# frozen_string_literal: true

# == Schema Information
#
# Table name: project_suggestions
#
#  id             :integer          not null, primary key
#  licenses       :string
#  notes          :text
#  repository_url :string
#  status         :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  project_id     :integer
#  user_id        :integer
#
class ProjectSuggestion < ApplicationRecord
  validates_presence_of :user, :project, :notes

  belongs_to :user
  belongs_to :project

  def done?
    return true if project.nil?
    !pending
  end

  def pending
    valid_repository_change? || valid_license_change? || valid_status_change?
  end

  def valid_repository_change?
    return false unless repository_url.present?
    repository_url != project.try(:repository_url)
  end

  def valid_license_change?
    return false unless licenses.present?
    licenses != project.try(:licenses)
  end

  def valid_status_change?
    return false unless status.present?
    return false if project.status.blank? && status == 'Active'
    status != project.try(:status)
  end
end
