class AddHiddenToGithubUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :github_users, :hidden, :boolean, default: false
    add_index :github_users, :hidden
  end
end
