class AddLastSyncedAtToGithubOrganisations < ActiveRecord::Migration
  def change
    add_column :github_organisations, :last_synced_at, :datetime
  end
end
