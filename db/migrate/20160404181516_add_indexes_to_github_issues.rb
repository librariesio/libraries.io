class AddIndexesToGithubIssues < ActiveRecord::Migration
  def change
    add_index :github_issues, :repository_id
  end
end
