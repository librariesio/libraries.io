# frozen_string_literal: true
class AddBioToGithubUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :github_users, :bio, :string
  end
end
