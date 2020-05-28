# frozen_string_literal: true

class AddIndexOnIssuesAndRepositoryUsers < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    commit_db_transaction
    add_index :issues, [:last_synced_at], algorithm: :concurrently
    add_index :repository_users, %i[hidden last_synced_at], algorithm: :concurrently
  end
end
