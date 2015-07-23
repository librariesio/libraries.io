class AddGithubIdIndexToRepos < ActiveRecord::Migration
  def change
    add_index :github_repositories, :github_id
  end
end
