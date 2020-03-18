# frozen_string_literal: true

class AddRepositoryUserIdToRepositories < ActiveRecord::Migration[5.0]
  def change
    add_column :repositories, :repository_user_id, :integer
    add_index :repositories, :repository_user_id
  end
end
