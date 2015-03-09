class AddLicenseFieldToGithubRepositories < ActiveRecord::Migration
  def change
    add_column :github_repositories, :license, :string
  end
end
