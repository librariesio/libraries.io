# frozen_string_literal: true

# == Schema Information
#
# Table name: repository_subscriptions
#
#  id                 :integer          not null, primary key
#  include_prerelease :boolean          default(TRUE)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  hook_id            :integer
#  repository_id      :integer
#  user_id            :integer
#
# Indexes
#
#  index_repository_subscriptions_on_created_at  (created_at)
#
class RepositorySubscription < ApplicationRecord
  belongs_to :user
  belongs_to :repository
  has_many :subscriptions

  after_commit :update_subscriptions, on: :update

  def update_subscriptions
    projects = []
    repository.repository_dependencies.each do |dep|
      if dep.project.present?
        project = dep.project.try(:id)
      elsif dep.project_name.present?
        project = Project.platform(dep.platform).where("lower(name) = ?", dep.project_name).first.try(:id)
      end
      projects << project
    end
    projects.compact!

    existing = subscriptions.map(&:project_id)

    subscriptions.where(project_id: (existing - projects)).delete_all
    (projects - existing).each do |project_id|
      subscriptions.create(project_id: project_id, include_prerelease: include_prerelease)
    end
    subscriptions.update_all(include_prerelease: include_prerelease)
  end
end
