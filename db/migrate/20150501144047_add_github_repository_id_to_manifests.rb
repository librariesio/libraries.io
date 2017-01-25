class AddGithubRepositoryIdToManifests < ActiveRecord::Migration
  def change
    add_column :manifests, :github_repository_id, :integer
  end
end
