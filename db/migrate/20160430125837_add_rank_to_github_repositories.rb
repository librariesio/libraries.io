class AddRankToGithubRepositories < ActiveRecord::Migration[5.0]
  def change
    add_column :github_repositories, :rank, :integer
  end
end
