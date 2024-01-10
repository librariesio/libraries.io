# frozen_string_literal: true

class AddSearchExtensions < ActiveRecord::Migration[7.0]
  def up
    safety_assured do
      execute "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
    end
  end

  def down
    safety_assured do
      execute "DROP EXTENSION IF EXISTS pg_trgm;"
    end
  end
end
