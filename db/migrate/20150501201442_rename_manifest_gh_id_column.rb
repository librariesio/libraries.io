class RenameManifestGhIdColumn < ActiveRecord::Migration
  def change
    rename_column :manifests, :github_repostory_id, :repository_id
  end
end
