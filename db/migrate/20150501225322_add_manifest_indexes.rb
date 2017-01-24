class AddManifestIndexes < ActiveRecord::Migration
  def change
    add_index :manifests, :repository_id
    add_index :repository_dependencies, :manifest_id
  end
end
