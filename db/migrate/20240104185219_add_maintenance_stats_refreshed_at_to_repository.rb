# frozen_string_literal: true

class AddMaintenanceStatsRefreshedAtToRepository < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :repositories, :maintenance_stats_refreshed_at, :datetime, if_not_exists: true
    add_index :repositories, :maintenance_stats_refreshed_at, algorithm: :concurrently, if_not_exists: true
  end
end
