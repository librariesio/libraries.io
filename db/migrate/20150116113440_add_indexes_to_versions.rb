class AddIndexesToVersions < ActiveRecord::Migration[5.0]
  def change
    add_index :versions, :project_id
    add_index :versions, :number
  end
end
