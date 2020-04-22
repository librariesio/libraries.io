# frozen_string_literal: true

class AddResearchedAtToVersions < ActiveRecord::Migration[5.2]
  def change
    add_column :versions, :researched_at, :timestamp
  end
end
