class AddEmailToGithubUsers < ActiveRecord::Migration
  def change
    add_column :github_users, :email, :string
  end
end
