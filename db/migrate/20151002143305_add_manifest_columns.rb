class AddManifestColumns < ActiveRecord::Migration
  def change
    rename_column :manifests, :name, :platform
    rename_column :manifests, :path, :filepath    
    add_column :manifests, :kind, :string
  end
end
