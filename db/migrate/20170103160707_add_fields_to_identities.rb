class AddFieldsToIdentities < ActiveRecord::Migration[5.0]
  def change
    add_column :identities, :token, :string
    add_column :identities, :nickname, :string
  end
end
