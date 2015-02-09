class AddGithubIdToGithubRepositories < ActiveRecord::Migration
  def change
    add_column :github_repositories, :github_id, :integer
  end
end
