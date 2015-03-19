class AddHiddenToGithubUsers < ActiveRecord::Migration
  def change
    add_column :github_users, :hidden, :boolean, default: false
    add_index :github_users, :hidden
  end
end
