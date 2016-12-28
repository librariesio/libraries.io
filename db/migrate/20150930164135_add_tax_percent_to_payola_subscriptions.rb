class AddTaxPercentToPayolaSubscriptions < ActiveRecord::Migration
  def change
    add_column :payola_subscriptions, :tax_percent, :integer
  end
end
