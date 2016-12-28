class CreatePayolaSubscriptions < ActiveRecord::Migration
  def change
    create_table :payola_subscriptions do |t|
      t.string :plan_type
      t.integer :plan_id
      t.timestamp :start
      t.string :status
      t.string :owner_type
      t.integer :owner_id
      t.string :stripe_customer_id
      t.boolean :cancel_at_period_end
      t.timestamp :current_period_start
      t.timestamp :current_period_end
      t.timestamp :ended_at
      t.timestamp :trial_start
      t.timestamp :trial_end
      t.timestamp :canceled_at
      t.integer :quantity
      t.string   :stripe_id
      t.string   :stripe_token
      t.string   :card_last4
      t.date     :card_expiration
      t.string   :card_type
      t.text     :error
      t.string   :state
      t.string   :email

      t.timestamps
    end
  end
end
