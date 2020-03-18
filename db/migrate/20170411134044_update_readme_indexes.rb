# frozen_string_literal: true

class UpdateReadmeIndexes < ActiveRecord::Migration[5.0]
  def change
    remove_index :readmes, :created_at
    remove_index :readmes, :repository_id
    add_index :readmes, :repository_id, unique: true
  end
end
