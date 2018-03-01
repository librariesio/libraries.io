class AddVersionsCompoundIndex < ActiveRecord::Migration[5.0]
  def change
    add_index :versions, [:project_id, :number]
  end
end
