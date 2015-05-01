class CreateRepositoryDependencies < ActiveRecord::Migration
  def change
    create_table :repository_dependencies do |t|
      t.integer :project_id
      t.integer :manifest_id
      t.boolean :optional
      t.string :project_name
      t.string :platform
      t.string :requirements
      t.string :kind

      t.timestamps null: false
    end
  end
end
