# frozen_string_literal: true
class AddGithubUserLoginIndex < ActiveRecord::Migration[5.0]
  def change
    add_index :github_users, :login
  end
end
