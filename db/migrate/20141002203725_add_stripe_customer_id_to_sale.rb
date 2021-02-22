# frozen_string_literal: true
class AddStripeCustomerIdToSale < ActiveRecord::Migration[5.0]
  def change
    add_column :payola_sales, :stripe_customer_id, :string, limit: 191
    add_index :payola_sales, :stripe_customer_id
  end
end
