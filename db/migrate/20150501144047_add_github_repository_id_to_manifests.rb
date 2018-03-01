class AddGithubRepositoryIdToManifests < ActiveRecord::Migration[5.0]
  def change
    add_column :manifests, :github_repository_id, :integer
  end
end
