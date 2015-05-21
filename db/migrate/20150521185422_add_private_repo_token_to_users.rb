class AddPrivateRepoTokenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :private_repo_token, :string
  end
end
