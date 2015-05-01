class RenameManifestGhIdColumn < ActiveRecord::Migration
  def change
    rename_column :manifests, :github_repostory_id, :github_repository_id
  end
end
