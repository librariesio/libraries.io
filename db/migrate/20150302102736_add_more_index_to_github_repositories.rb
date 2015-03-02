class AddMoreIndexToGithubRepositories < ActiveRecord::Migration
  def change
    add_index :github_repositories, :full_name
  end
end
