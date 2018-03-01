class AddGithubIdIndexToGithubUsers < ActiveRecord::Migration[5.0]
  def change
    add_index :github_users, :github_id
    add_index :projects, :versions_count
    add_index :github_tags, [:github_repository_id, :name]
  end
end
