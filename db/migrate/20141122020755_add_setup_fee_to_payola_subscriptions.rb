class AddSetupFeeToPayolaSubscriptions < ActiveRecord::Migration
  def change
    add_column :payola_subscriptions, :setup_fee, :integer
  end
end
