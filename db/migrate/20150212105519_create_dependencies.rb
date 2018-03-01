class CreateDependencies < ActiveRecord::Migration[5.0]
  def change
    create_table :dependencies do |t|
      t.integer :version_id
      t.integer :project_id
      t.string :project_name
      t.string :platform
      t.string :kind
      t.boolean :optional, default: false
      t.string :requirements
    end
  end
end
