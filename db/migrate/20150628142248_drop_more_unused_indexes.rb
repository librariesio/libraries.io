class DropMoreUnusedIndexes < ActiveRecord::Migration
  def change
    remove_index :versions, column: :number
    remove_index :dependencies, column: :created_at
    remove_index :github_tags, column: :created_at
    remove_index :github_tags, column: :name
    remove_index :github_contributions, column: :created_at
    remove_index :versions, column: :published_at
  end
end
