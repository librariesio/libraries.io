class AddCreatedAtIndexToDependencies < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    unless index_name_exists?(:dependencies, "index_dependencies_on_created_at_date")
      add_index :dependencies, "(created_at::date)", name: "index_dependencies_on_created_at_date", algorithm: :concurrently
    end

    unless index_name_exists?(:repository_dependencies, "index_repository_dependencies_on_created_at_date")
      add_index :repository_dependencies, "(created_at::date)", name: "index_repository_dependencies_on_created_at_date", algorithm: :concurrently
    end

  end

  def down
    if index_name_exists?(:dependencies, "index_dependencies_on_created_at_date")
      remove_index :dependencies, "(created_at::date)"
    end

    if index_name_exists?(:repository_dependencies, "index_repository_dependencies_on_created_at_date")
      remove_index :repository_dependencies, "(created_at::date)"
    end
  end
end
