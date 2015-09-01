class AddTokenUpgradeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :token_upgrade, :boolean, default: false
  end
end
