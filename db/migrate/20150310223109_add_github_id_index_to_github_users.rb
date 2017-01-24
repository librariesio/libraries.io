class AddGithubIdIndexToGithubUsers < ActiveRecord::Migration
  def change
    add_index :github_users, :github_id
    add_index :projects, :versions_count
    add_index :github_tags, [:repository_id, :name]
  end
end
