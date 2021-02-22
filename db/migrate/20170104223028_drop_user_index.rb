# frozen_string_literal: true
class DropUserIndex < ActiveRecord::Migration[5.0]
  def change
    remove_index :users, :nickname
    change_column_null :users, :nickname, true
    change_column_null :users, :uid, true
  end
end
