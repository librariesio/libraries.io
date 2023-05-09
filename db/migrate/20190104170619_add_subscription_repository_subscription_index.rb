# frozen_string_literal: true

class AddSubscriptionRepositorySubscriptionIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :subscriptions, [:repository_subscription_id]
  end
end
