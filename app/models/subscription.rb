# frozen_string_literal: true

# == Schema Information
#
# Table name: subscriptions
#
#  id                         :integer          not null, primary key
#  include_prerelease         :boolean          default(TRUE)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  project_id                 :integer
#  repository_subscription_id :integer
#  user_id                    :integer
#
# Indexes
#
#  index_subscriptions_on_created_at                  (created_at)
#  index_subscriptions_on_project_id                  (project_id)
#  index_subscriptions_on_repository_subscription_id  (repository_subscription_id)
#  index_subscriptions_on_user_id_and_project_id      (user_id,project_id)
#
class Subscription < ApplicationRecord
  validates_presence_of :project
  validates_uniqueness_of :project, scope: :user_id, if: :user_id_present?
  belongs_to :project
  belongs_to :user
  belongs_to :repository_subscription
  has_one :repository, through: :repository_subscription

  scope :with_user, -> { joins(:user) }
  scope :with_repository_subscription, -> { joins(:repository_subscription) }
  scope :include_prereleases, -> { where(include_prerelease: true) }
  scope :users_present, -> { where.not(user_id: nil) }
  scope :users_nil, -> { where(user_id: nil) }

  def notification_user
    repository_subscription.try(:user) || user
  end

  def user_id_present?
    user_id.present?
  end
end
