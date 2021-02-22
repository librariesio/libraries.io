# frozen_string_literal: true
class RenameGithubIdOnRepositoryUsers < ActiveRecord::Migration[5.0]
  def change
    rename_column :repository_users, :github_id, :uuid
    rename_column :repository_organisations, :github_id, :uuid
    add_column :repository_users, :host_type, :string
    add_column :repository_organisations, :host_type, :string
  end
end
