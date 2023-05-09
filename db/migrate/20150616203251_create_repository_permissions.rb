# frozen_string_literal: true

class CreateRepositoryPermissions < ActiveRecord::Migration[5.0]
  def change
    create_table :repository_permissions do |t|
      t.integer :user_id
      t.integer :github_repository_id
      t.boolean :admin
      t.boolean :push
      t.boolean :pull

      t.timestamps null: false
    end
  end
end
