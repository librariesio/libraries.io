# frozen_string_literal: true
class AddIndexesToGithubIssues < ActiveRecord::Migration[5.0]
  def change
    add_index :github_issues, :github_repository_id
  end
end
