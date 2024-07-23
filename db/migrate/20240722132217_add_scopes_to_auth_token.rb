# frozen_string_literal: true

class AddScopesToAuthToken < ActiveRecord::Migration[7.0]
  def up
    add_column :auth_tokens, :scopes, :string, array: true
    change_column_default :auth_tokens, :scopes, []
  end

  def down
    remove_column :auth_tokens, :scopes
  end
end
