# frozen_string_literal: true

class AddRepositorySourcesToVersions < ActiveRecord::Migration[5.2]
  def up
    add_column :versions, :repository_sources, :jsonb
    change_column_default :versions, :repository_sources, []
  end

  def down
    remove_column :versions, :repository_sources
  end
end
