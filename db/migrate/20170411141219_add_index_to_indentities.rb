# frozen_string_literal: true
class AddIndexToIndentities < ActiveRecord::Migration[5.0]
  def change
    add_index :identities, :user_id
  end
end
