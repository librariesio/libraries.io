class AddStatusToGithubRepositories < ActiveRecord::Migration
  def change
    add_column :github_repositories, :status, :string
  end
end
