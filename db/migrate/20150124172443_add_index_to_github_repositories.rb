class AddIndexToGithubRepositories < ActiveRecord::Migration[5.0]
  def change
    add_index :github_repositories, :project_id
  end
end
