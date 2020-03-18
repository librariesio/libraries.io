# frozen_string_literal: true

class AddAddressesToPayolaSubscription < ActiveRecord::Migration[5.0]
  def change
    add_column :payola_subscriptions, :customer_address, :text
    add_column :payola_subscriptions, :business_address, :text
  end
end
