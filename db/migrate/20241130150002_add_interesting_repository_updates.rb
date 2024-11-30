# frozen_string_literal: true

class AddInterestingRepositoryUpdates < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :repositories, :interesting, :boolean
    # safety_assured: the default is fine because the table is small
    safety_assured do
      add_column :web_hooks, :interesting_repository_updates, :boolean, default: false, null: false
    end
    add_index :repositories, :interesting, algorithm: :concurrently

    # to start, everything with maint stats is interesting
    Repository.where.not(maintenance_stats_refreshed_at: nil).update_all(interesting: true)
  end
end
