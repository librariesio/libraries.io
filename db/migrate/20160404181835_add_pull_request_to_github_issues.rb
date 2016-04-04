class AddPullRequestToGithubIssues < ActiveRecord::Migration
  def change
    add_column :github_issues, :pull_request, :boolean
  end
end
