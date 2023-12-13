# frozen_string_literal: true

class AddPublishedAtIndexToVersions < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :versions, :published_at, algorithm: :concurrently
  end
end
