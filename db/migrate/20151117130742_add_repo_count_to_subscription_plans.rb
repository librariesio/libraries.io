class AddRepoCountToSubscriptionPlans < ActiveRecord::Migration
  def change
    add_column :subscription_plans, :repo_count, :integer
  end
end
