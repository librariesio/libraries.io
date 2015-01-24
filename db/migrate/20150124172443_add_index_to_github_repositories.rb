class AddIndexToGithubRepositories < ActiveRecord::Migration
  def change
    add_index :github_repositories, :project_id
  end
end
