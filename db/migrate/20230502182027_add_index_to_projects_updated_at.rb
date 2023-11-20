# frozen_string_literal: true

class AddIndexToProjectsUpdatedAt < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :projects, :updated_at, algorithm: :concurrently unless index_exists?(:projects, :updated_at)
  end
end
