class AddRankToGithubRepositories < ActiveRecord::Migration
  def change
    add_column :github_repositories, :rank, :integer
  end
end
