class AddRepositoryIdToManifests < ActiveRecord::Migration
  def change
    add_column :manifests, :repository_id, :integer
  end
end
