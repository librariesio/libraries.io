class AddRuntimeDependenciesCountToProjects < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :runtime_dependencies_count, :integer
  end
end
