# frozen_string_literal: true

class AddRepositoryIdToRepositoryDependencies < ActiveRecord::Migration[5.1]
  def change
    add_column :repository_dependencies, :repository_id, :integer
  end
end
