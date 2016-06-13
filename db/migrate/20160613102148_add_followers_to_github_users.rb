class AddFollowersToGithubUsers < ActiveRecord::Migration
  def change
    add_column :github_users, :followers, :integer
    add_column :github_users, :following, :integer
  end
end
