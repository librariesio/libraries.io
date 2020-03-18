# frozen_string_literal: true

class AddLastSyncedAtToGithubRepositories < ActiveRecord::Migration[5.0]
  def change
    add_column :github_repositories, :last_synced_at, :datetime
  end
end
