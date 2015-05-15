class AddVersionsCompoundIndex < ActiveRecord::Migration
  def change
    add_index :versions, [:project_id, :number]
  end
end
