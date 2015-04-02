class AddUpdatedAtIndexToProjects < ActiveRecord::Migration
  def change
    add_index :projects, :updated_at
  end
end
