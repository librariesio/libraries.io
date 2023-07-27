# frozen_string_literal: true

class AddStatusCheckedAtToProjects < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_column :projects, :status_checked_at, :datetime
    add_index :projects, :status_checked_at, algorithm: :concurrently
  end
end
