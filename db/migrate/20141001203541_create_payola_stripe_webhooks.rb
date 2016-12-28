class CreatePayolaStripeWebhooks < ActiveRecord::Migration
  def change
    create_table :payola_stripe_webhooks do |t|
      t.string :stripe_id

      t.timestamps
    end
  end
end
