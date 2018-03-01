class AddManifestColumns < ActiveRecord::Migration[5.0]
  def change
    rename_column :manifests, :name, :platform
    rename_column :manifests, :path, :filepath    
    add_column :manifests, :kind, :string
  end
end
