class AddStripeStatusToPayolaSubscription < ActiveRecord::Migration
  def change
    add_column :payola_subscriptions, :stripe_status, :string
  end
end
