class AddUniqueIndexToRepositoryPermissions < ActiveRecord::Migration
  def change
    add_index :repository_permissions, [:user_id, :repository_id], :unique => true, name: 'user_repo_unique_repository_permissions'
  end
end
