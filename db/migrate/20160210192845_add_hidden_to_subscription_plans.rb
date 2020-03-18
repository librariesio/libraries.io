# frozen_string_literal: true

class AddHiddenToSubscriptionPlans < ActiveRecord::Migration[5.0]
  def change
    add_column :subscription_plans, :hidden, :boolean, default: false
  end
end
