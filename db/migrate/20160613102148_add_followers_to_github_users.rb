# frozen_string_literal: true

class AddFollowersToGithubUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :github_users, :followers, :integer
    add_column :github_users, :following, :integer
  end
end
