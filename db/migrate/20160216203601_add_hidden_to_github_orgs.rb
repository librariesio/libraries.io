class AddHiddenToGithubOrgs < ActiveRecord::Migration
  def change
    add_column :github_organisations, :hidden, :boolean, default: false
    add_index :github_organisations, :hidden
  end
end
