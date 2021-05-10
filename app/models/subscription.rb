# frozen_string_literal: true
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
