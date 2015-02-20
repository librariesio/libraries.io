class AddDependencyIndexes < ActiveRecord::Migration
  def change
    add_index(:dependencies, :version_id)
    add_index(:dependencies, [:platform, :project_name])
  end
end
