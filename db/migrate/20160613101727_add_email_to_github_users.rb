# frozen_string_literal: true
class AddEmailToGithubUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :github_users, :email, :string
  end
end
