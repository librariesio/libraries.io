# frozen_string_literal: true

class CreateProjectMutes < ActiveRecord::Migration[5.0]
  def change
    create_table :project_mutes do |t|
      t.integer :user_id, null: false
      t.integer :project_id, null: false
      t.index %i[project_id user_id], unique: true
      t.timestamps null: false
    end
  end
end
