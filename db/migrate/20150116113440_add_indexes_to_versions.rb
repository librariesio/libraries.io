class AddIndexesToVersions < ActiveRecord::Migration
  def change
    add_index :versions, :project_id
    add_index :versions, :number
  end
end
