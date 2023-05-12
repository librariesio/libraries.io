# frozen_string_literal: true

class DropUnusedIndexes < ActiveRecord::Migration[5.0]
  def change
    remove_index :dependencies, column: %i[platform project_name]
    remove_index :github_contributions, column: :platform
    remove_index :github_users, name: :index_github_users_on_login
  end
end
