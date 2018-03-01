class AddPrivateFieldToGithubRepositories < ActiveRecord::Migration[5.0]
  def change
    add_column :github_repositories, :private, :boolean
  end
end
