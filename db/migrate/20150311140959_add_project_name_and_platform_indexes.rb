class AddProjectNameAndPlatformIndexes < ActiveRecord::Migration
  def change
    add_index :projects, [:name, :platform]
    add_index :versions, :published_at
  end
end
