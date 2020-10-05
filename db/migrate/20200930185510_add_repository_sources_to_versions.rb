# frozen_string_literal: true

class AddRepositorySourcesToVersions < ActiveRecord::Migration[5.2]
  def change
    add_column :versions, :repository_sources, :jsonb
  end
end
