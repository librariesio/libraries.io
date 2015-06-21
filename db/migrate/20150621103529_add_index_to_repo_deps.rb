class AddIndexToRepoDeps < ActiveRecord::Migration
  def change
    add_index :repository_dependencies, :project_id
  end
end
