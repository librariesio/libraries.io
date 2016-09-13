class AddSyncingFieldsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :currently_syncing, :boolean, default: false, null: false
    add_column :users, :last_synced_at, :datetime
  end
end
