class AddGithubUserLoginIndex < ActiveRecord::Migration
  def change
    add_index :github_users, :login
  end
end
