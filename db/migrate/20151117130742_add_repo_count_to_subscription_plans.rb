# frozen_string_literal: true
class AddRepoCountToSubscriptionPlans < ActiveRecord::Migration[5.0]
  def change
    add_column :subscription_plans, :repo_count, :integer
  end
end
