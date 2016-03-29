class AddIndexOnGithubRepositoriesStatus < ActiveRecord::Migration
  def change
    add_index :github_repositories, :status
  end
end
