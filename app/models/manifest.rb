class Manifest < ActiveRecord::Base
  belongs_to :user
  has_many :subscriptions, dependent: :destroy
end
