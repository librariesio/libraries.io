class AddSyncingFieldsToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :currently_syncing, :boolean, default: false, null: false
    add_column :users, :last_synced_at, :datetime
  end
end
