class RemoveDuplicateIndexes < ActiveRecord::Migration
  def change
    remove_index :github_contributions, column: :github_repository_id
    remove_index :github_tags, column: :github_repository_id
    remove_index :versions, column: :project_id
  end
end
