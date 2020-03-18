# frozen_string_literal: true

class AddPullRequestToGithubIssues < ActiveRecord::Migration[5.0]
  def change
    add_column :github_issues, :pull_request, :boolean
  end
end
