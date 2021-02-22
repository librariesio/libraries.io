# frozen_string_literal: true
class AddRepositorySubscriptionIdToSubscriptions < ActiveRecord::Migration[5.0]
  def change
    add_column :subscriptions, :repository_subscription_id, :integer
  end
end
