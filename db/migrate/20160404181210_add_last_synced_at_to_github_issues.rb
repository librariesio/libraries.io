class AddLastSyncedAtToGithubIssues < ActiveRecord::Migration
  def change
    add_column :github_issues, :last_synced_at, :datetime
  end
end
