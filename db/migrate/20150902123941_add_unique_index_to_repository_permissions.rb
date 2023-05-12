# frozen_string_literal: true

class AddUniqueIndexToRepositoryPermissions < ActiveRecord::Migration[5.0]
  def change
    add_index :repository_permissions, %i[user_id github_repository_id], unique: true, name: "user_repo_unique_repository_permissions"
  end
end
