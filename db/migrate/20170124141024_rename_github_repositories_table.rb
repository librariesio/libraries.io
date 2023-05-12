# frozen_string_literal: true

class RenameGithubRepositoriesTable < ActiveRecord::Migration[5.0]
  def change
    rename_table :github_repositories, :repositories
    rename_column :github_contributions, :github_repository_id, :repository_id
    rename_column :github_issues, :github_repository_id, :repository_id
    rename_column :github_tags, :github_repository_id, :repository_id
    rename_column :manifests, :github_repository_id, :repository_id
    rename_column :projects, :github_repository_id, :repository_id
    rename_column :readmes, :github_repository_id, :repository_id
    rename_column :repository_permissions, :github_repository_id, :repository_id
    rename_column :repository_subscriptions, :github_repository_id, :repository_id
    rename_column :web_hooks, :github_repository_id, :repository_id
  end
end
