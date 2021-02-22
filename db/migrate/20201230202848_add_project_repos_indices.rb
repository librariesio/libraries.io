# frozen_string_literal: true
class AddProjectReposIndices < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :projects, [:status], algorithm: :concurrently
    add_index :repositories, [:fork], algorithm: :concurrently
    add_index :repositories, [:private], algorithm: :concurrently
  end
end
