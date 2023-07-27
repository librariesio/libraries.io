# frozen_string_literal: true

class AddCreatedAtIndexToDependencies < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    add_index :dependencies, "project_id, (created_at::date)", name: "index_dependencies_on_project_created_at_date", algorithm: :concurrently unless index_name_exists?(:dependencies, "index_dependencies_on_project_created_at_date")

    add_index :repository_dependencies, "project_id, (created_at::date)", name: "index_repository_dependencies_on_project_created_at_date", algorithm: :concurrently unless index_name_exists?(:repository_dependencies, "index_repository_dependencies_on_project_created_at_date")
  end

  def down
    remove_index :dependencies, name: "index_dependencies_on_project_created_at_date" if index_name_exists?(:dependencies, "index_dependencies_on_project_created_at_date")

    remove_index :repository_dependencies, name: "index_repository_dependencies_on_project_created_at_date" if index_name_exists?(:repository_dependencies, "index_repository_dependencies_on_project_created_at_date")
  end
end
