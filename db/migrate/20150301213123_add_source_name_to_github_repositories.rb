class AddSourceNameToGithubRepositories < ActiveRecord::Migration
  def change
    add_column :github_repositories, :source_name, :string
  end
end
