# frozen_string_literal: true
class AddTaxPercentToPayolaSubscriptions < ActiveRecord::Migration[5.0]
  def change
    add_column :payola_subscriptions, :tax_percent, :integer
  end
end
