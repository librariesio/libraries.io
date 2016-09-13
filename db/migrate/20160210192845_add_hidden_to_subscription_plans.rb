class AddHiddenToSubscriptionPlans < ActiveRecord::Migration
  def change
    add_column :subscription_plans, :hidden, :boolean, default: false
  end
end
