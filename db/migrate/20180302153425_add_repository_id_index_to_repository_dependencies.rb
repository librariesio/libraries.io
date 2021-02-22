# frozen_string_literal: true
class AddRepositoryIdIndexToRepositoryDependencies < ActiveRecord::Migration[5.1]
  def change
    add_index :repository_dependencies, :repository_id
  end
end
