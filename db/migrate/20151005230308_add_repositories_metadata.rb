class AddRepositoriesMetadata < ActiveRecord::Migration[5.0]
  def change
    add_column :github_repositories, :has_readme, :string
    add_column :github_repositories, :has_changelog, :string
    add_column :github_repositories, :has_contributing, :string
    add_column :github_repositories, :has_license, :string
    add_column :github_repositories, :has_coc, :string
    add_column :github_repositories, :has_threat_model, :string
    add_column :github_repositories, :has_audit, :string
  end
end
