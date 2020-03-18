# frozen_string_literal: true

class RenameGithubIssuesTable < ActiveRecord::Migration[5.0]
  def change
    rename_table :github_issues, :issues
  end
end
