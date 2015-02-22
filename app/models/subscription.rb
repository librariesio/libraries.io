class Subscription < ActiveRecord::Base
  validates_presence_of :project, :user
  validates_uniqueness_of :project, scope: :user_id
  belongs_to :project
  belongs_to :user
end
