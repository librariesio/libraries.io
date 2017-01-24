class RemoveDuplicateIndexes < ActiveRecord::Migration
  def change
    remove_index :github_contributions, column: :repository_id
    remove_index :github_tags, column: :repository_id
    remove_index :versions, column: :project_id
  end
end
