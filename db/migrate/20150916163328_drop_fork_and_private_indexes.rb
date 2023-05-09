# frozen_string_literal: true

class DropForkAndPrivateIndexes < ActiveRecord::Migration[5.0]
  def change
    remove_index :github_repositories, :fork
    remove_index :github_repositories, :private
  end
end
