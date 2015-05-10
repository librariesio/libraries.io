class Subscription < ActiveRecord::Base
  validates_presence_of :project
  validates_uniqueness_of :project, scope: :user_id, if: 'user_id.present?'
  belongs_to :project
  belongs_to :user
  belongs_to :repository_subscription

  scope :with_user, -> { joins(:user) }

  def notification_user
    user
  end
end
