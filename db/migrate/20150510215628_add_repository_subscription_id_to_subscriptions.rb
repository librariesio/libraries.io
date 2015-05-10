class AddRepositorySubscriptionIdToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :repository_subscription_id, :integer
  end
end
