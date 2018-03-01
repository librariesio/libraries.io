class AddGithubContributionsCountToGithubRepositories < ActiveRecord::Migration[5.0]
  def change
    add_column :github_repositories, :github_contributions_count, :integer, default: 0, null: false
    add_index :github_repositories, :github_contributions_count
  end
end
