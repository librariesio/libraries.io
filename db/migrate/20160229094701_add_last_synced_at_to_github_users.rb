class AddLastSyncedAtToGithubUsers < ActiveRecord::Migration
  def change
    add_column :github_users, :last_synced_at, :datetime
  end
end
