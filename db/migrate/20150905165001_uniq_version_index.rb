# frozen_string_literal: true

class UniqVersionIndex < ActiveRecord::Migration[5.0]
  def change
    remove_index :versions, %i[project_id number]
    add_index :versions, %i[project_id number], unique: true
  end
end
