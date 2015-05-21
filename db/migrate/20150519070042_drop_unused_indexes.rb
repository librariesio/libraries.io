class DropUnusedIndexes < ActiveRecord::Migration
  def change
    remove_index :dependencies, column: [:platform, :project_name]
    remove_index :github_contributions, column: :platform
    remove_index :github_users, column: :login
  end
end
