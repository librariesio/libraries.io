class AddVersionProjectIdToDependency < ActiveRecord::Migration[5.2]
  def change
    add_column :dependencies, :version_project_id, :integer
  end
end
