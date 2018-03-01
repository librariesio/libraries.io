class AddGithubOrganisationIdToGithubRepositories < ActiveRecord::Migration[5.0]
  def change
    add_column :github_repositories, :github_organisation_id, :integer
  end
end
