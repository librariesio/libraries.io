# frozen_string_literal: true
class ChangeGithubProjectRelationship < ActiveRecord::Migration[5.0]
  def change
    remove_column :github_repositories, :project_id
    add_column :projects, :github_repository_id, :integer
  end
end
