class AddFieldsToIdentities < ActiveRecord::Migration[5.0]
  def change
    add_column :identities, :token, :string
    add_column :identities, :nickname, :string
    add_column :identities, :public_repo_token, :string
    add_column :identities, :private_repo_token, :string
  end
end
