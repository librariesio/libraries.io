class AddLastSyncedAtToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :last_synced_at, :datetime
  end
end
