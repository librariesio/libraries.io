class AddGithubRepositoryIdIndex < ActiveRecord::Migration
  def change
    add_index(:projects, :github_repository_id)
  end
end
