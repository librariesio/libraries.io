# frozen_string_literal: true

class AddIndexToVersionsUpdatedAt < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :versions, :updated_at, algorithm: :concurrently
  end
end
