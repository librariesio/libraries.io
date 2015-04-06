class AddIndexesToGithubOrgs < ActiveRecord::Migration
  def change
    add_index :github_organisations, :login
    add_index :github_organisations, :github_id
    add_index :github_repositories, :github_organisation_id
  end
end
