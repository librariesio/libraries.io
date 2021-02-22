# frozen_string_literal: true
class RenameGithubUserFields < ActiveRecord::Migration[5.0]
  def change
    rename_column :contributions, :github_user_id, :repository_user_id
    rename_column :issues, :github_user_id, :repository_user_id
    rename_column :repositories, :github_organisation_id, :repository_organisation_id
  end
end
