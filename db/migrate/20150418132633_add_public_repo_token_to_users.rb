class AddPublicRepoTokenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :public_repo_token, :string
  end
end
