class AddGithubOrganisationIdToGithubRepositories < ActiveRecord::Migration
  def change
    add_column :github_repositories, :github_organisation_id, :integer
  end
end
