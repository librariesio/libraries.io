class AddLastSyncedAtToGithubIssues < ActiveRecord::Migration[5.0]
  def change
    add_column :github_issues, :last_synced_at, :datetime
  end
end
