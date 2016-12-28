class AddGuidToPayolaSubscriptions < ActiveRecord::Migration
  def change
    add_column :payola_subscriptions, :guid, :string, limit: 191
    add_index :payola_subscriptions, :guid
  end
end
