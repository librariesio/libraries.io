class AddVersionProjectIdToDependency < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_column :dependencies, :version_project_id, :integer
    remove_index :dependencies, :project_id
    add_index :dependencies, [:project_id, :version_project_id], algorithm: :concurrently
  end
end
