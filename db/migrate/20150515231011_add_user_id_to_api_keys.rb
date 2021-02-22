# frozen_string_literal: true
class AddUserIdToApiKeys < ActiveRecord::Migration[5.0]
  def change
    add_column :api_keys, :user_id, :integer
    add_column :api_keys, :deleted_at, :datetime
    add_index :api_keys, :user_id
    add_index :api_keys, :access_token
  end
end
