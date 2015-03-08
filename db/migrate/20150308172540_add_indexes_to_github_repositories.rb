class AddIndexesToGithubRepositories < ActiveRecord::Migration
  def change
    add_index :github_repositories, :owner_id
  end
end
