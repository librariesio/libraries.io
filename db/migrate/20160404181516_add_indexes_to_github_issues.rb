class AddIndexesToGithubIssues < ActiveRecord::Migration
  def change
    add_index :github_issues, :github_repository_id
  end
end
