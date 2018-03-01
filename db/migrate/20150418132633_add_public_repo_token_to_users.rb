class AddPublicRepoTokenToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :public_repo_token, :string
  end
end
