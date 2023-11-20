# frozen_string_literal: true

class RenameManifestGhIdColumn < ActiveRecord::Migration[5.0]
  def change
    rename_column :manifests, :github_repostory_id, :github_repository_id
  end
end
