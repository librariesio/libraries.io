# frozen_string_literal: true

class AddLastSyncedAtToGithubOrganisations < ActiveRecord::Migration[5.0]
  def change
    add_column :github_organisations, :last_synced_at, :datetime
  end
end
