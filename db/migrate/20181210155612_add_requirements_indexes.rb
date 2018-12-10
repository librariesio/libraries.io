class AddRequirementsIndexes < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :dependencies, [:project_id, :requirements], algorithm: :concurrently
    add_index :repository_dependencies, [:project_id, :requirements], algorithm: :concurrently
  end
end
