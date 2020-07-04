class CreateDeletedProjects < ActiveRecord::Migration[5.2]
  def change
    create_table :deleted_projects do |t|
      t.string "digest", null: false
      t.timestamps
    end

    add_index :deleted_projects, [:digest], unique: true
    add_index :deleted_projects, :updated_at
  end
end
