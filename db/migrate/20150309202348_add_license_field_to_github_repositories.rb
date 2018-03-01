class AddLicenseFieldToGithubRepositories < ActiveRecord::Migration[5.0]
  def change
    add_column :github_repositories, :license, :string
  end
end
