class CreateProjectMutes < ActiveRecord::Migration
  def change
    create_table :project_mutes do |t|
      t.integer :user_id, null: false
      t.integer :project_id, null: false
      t.index [:project_id, :user_id], :unique => true
      t.timestamps null: false
    end
  end
end
