class Subscription < ApplicationRecord
  validates_presence_of :project
  validates_uniqueness_of :project, scope: :user_id, if: 'user_id.present?'
  belongs_to :project
  belongs_to :user
  belongs_to :repository_subscription
  has_one :github_repository, through: :repository_subscription

  scope :with_user, -> { joins(:user) }
  scope :with_repository_subscription, -> { joins(:repository_subscription) }
  scope :include_prereleases, -> { where(include_prerelease: true) }

  def notification_user
    repository_subscription.try(:user) || user
  end
end
