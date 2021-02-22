# frozen_string_literal: true
class DropEvenMoreUnusedIndexes < ActiveRecord::Migration[5.0]
  def change
    remove_index :versions, column: :created_at
    remove_index :projects, column: :language
    remove_index :projects, name: :index_projects_on_platform
    remove_index :github_repositories, column: :license
    remove_index :github_repositories, column: :language
    remove_index :github_repositories, column: :github_contributions_count
    remove_index :github_repositories, column: :created_at
    remove_index :github_repositories, column: :github_organisation_id
  end
end
