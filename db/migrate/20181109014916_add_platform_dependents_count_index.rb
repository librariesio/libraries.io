# frozen_string_literal: true
class AddPlatformDependentsCountIndex < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :projects, [:platform, :dependents_count], algorithm: :concurrently
  end
end
