class AddLastSyncedAtToGithubRepositories < ActiveRecord::Migration
  def change
    add_column :github_repositories, :last_synced_at, :datetime
  end
end
