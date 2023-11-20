# frozen_string_literal: true

class DropOldUserFields < ActiveRecord::Migration[5.0]
  def change
    remove_column :users, :uid
    remove_column :users, :nickname
    remove_column :users, :token
    remove_column :users, :name
    remove_column :users, :public_repo_token
    remove_column :users, :private_repo_token
  end
end
