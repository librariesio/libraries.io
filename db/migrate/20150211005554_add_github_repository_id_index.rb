# frozen_string_literal: true
class AddGithubRepositoryIdIndex < ActiveRecord::Migration[5.0]
  def change
    add_index(:projects, :github_repository_id)
  end
end
