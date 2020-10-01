# frozen_string_literal: true

class AddSourcesToVersions < ActiveRecord::Migration[5.2]
  def up
    add_column :versions, :sources, :jsonb
    change_column_default :versions, :sources, []
  end

  def down
    remove_column :versions, :sources
  end
end
