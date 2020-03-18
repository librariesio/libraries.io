# frozen_string_literal: true

class CreateRepositoryDependencies < ActiveRecord::Migration[5.0]
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
