# frozen_string_literal: true
class AddLastSyncedAtToGithubUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :github_users, :last_synced_at, :datetime
  end
end
