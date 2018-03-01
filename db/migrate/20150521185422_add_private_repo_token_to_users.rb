class AddPrivateRepoTokenToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :private_repo_token, :string
  end
end
