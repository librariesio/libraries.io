class CreateProjectUpdatePriorities < ActiveRecord::Migration[5.2]
  def change
    create_table :project_update_priorities do |t|
      t.references :project, unique: true
      t.integer :priority, default: 0
      t.timestamps
    end
  end
end
