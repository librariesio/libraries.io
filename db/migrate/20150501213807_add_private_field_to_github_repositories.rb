class AddPrivateFieldToGithubRepositories < ActiveRecord::Migration
  def change
    add_column :github_repositories, :private, :boolean
  end
end
