class AddLastSyncedAtToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :last_synced_at, :datetime
  end
end
