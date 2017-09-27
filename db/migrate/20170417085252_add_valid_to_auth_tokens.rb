class AddValidToAuthTokens < ActiveRecord::Migration[5.0]
  def change
    add_column :auth_tokens, :authorized, :boolean
  end
end
