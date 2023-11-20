# frozen_string_literal: true

class RemoveDuplicateIndexes < ActiveRecord::Migration[5.0]
  def change
    remove_index :github_contributions, column: :github_repository_id
    remove_index :github_tags, column: :github_repository_id
    remove_index :versions, column: :project_id
  end
end
