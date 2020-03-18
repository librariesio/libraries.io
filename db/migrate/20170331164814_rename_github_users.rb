# frozen_string_literal: true

class RenameGithubUsers < ActiveRecord::Migration[5.0]
  def change
    rename_table :github_users, :repository_users
    rename_table :github_organisations, :repository_organisations
  end
end
