class AddBioToGithubUsers < ActiveRecord::Migration
  def change
    add_column :github_users, :bio, :string
  end
end
