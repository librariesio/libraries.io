class AddUpdatedAtIndexToProjects < ActiveRecord::Migration
  def change
    add_index :projects, :updated_at
    add_index :projects, :created_at
  end
end
