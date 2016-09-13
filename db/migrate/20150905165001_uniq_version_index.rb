class UniqVersionIndex < ActiveRecord::Migration
  def change
    remove_index :versions, [:project_id, :number]
    add_index :versions, [:project_id, :number], :unique => true
  end
end
