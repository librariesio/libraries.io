class AddSourceNameIndexToGithubRepositories < ActiveRecord::Migration
  def change
    add_index :github_repositories, :source_name
  end
end
