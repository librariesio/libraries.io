# frozen_string_literal: true
class DropSomeUserFields < ActiveRecord::Migration[5.0]
  def change
    remove_column :users, :token_upgrade
    remove_column :users, :gravatar_id
    remove_column :users, :location
    remove_column :users, :blog
  end
end
