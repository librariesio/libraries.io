class AddFieldsToGithubUsers < ActiveRecord::Migration
  def change
    add_column :github_users, :name, :string
    add_column :github_users, :company, :string
    add_column :github_users, :blog, :string
    add_column :github_users, :location, :string
  end
end
