# frozen_string_literal: true
class DropPayolaTables < ActiveRecord::Migration[5.0]
  def change
    drop_table :payola_affiliates
    drop_table :payola_coupons
    drop_table :payola_sales
    drop_table :payola_stripe_webhooks
    drop_table :payola_subscriptions
    drop_table :subscription_plans
  end
end
