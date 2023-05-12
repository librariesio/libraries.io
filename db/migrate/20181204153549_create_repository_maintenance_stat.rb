# frozen_string_literal: true

class CreateRepositoryMaintenanceStat < ActiveRecord::Migration[5.1]
  def change
    create_table :repository_maintenance_stats do |t|
      t.references :repository
      t.string :category
      t.string :value # just store it as string and make the whatever is reading the stats serialize it

      t.timestamps
    end
  end
end
