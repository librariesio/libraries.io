class AddRuntimeDependenciesCountToVersions < ActiveRecord::Migration[5.1]
  def change
    add_column :versions, :runtime_dependencies_count, :integer
  end
end
