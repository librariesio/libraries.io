class DropForkAndPrivateIndexes < ActiveRecord::Migration
  def change
    remove_index :github_repositories, :fork
    remove_index :github_repositories, :private
  end
end
