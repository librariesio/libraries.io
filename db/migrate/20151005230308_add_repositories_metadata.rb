class AddRepositoriesMetadata < ActiveRecord::Migration
  def change
    add_column :github_repositories, :has_readme, :boolean, default: false
    add_column :github_repositories, :has_changelog, :boolean, default: false
    add_column :github_repositories, :has_contributing, :boolean, default: false
    add_column :github_repositories, :has_license, :boolean, default: false
    add_column :github_repositories, :has_coc, :boolean, default: false
    add_column :github_repositories, :has_threat_model, :boolean, default: false
  end
end
