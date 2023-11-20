# frozen_string_literal: true

class AddVersionsCompoundIndex < ActiveRecord::Migration[5.0]
  def change
    add_index :versions, %i[project_id number]
  end
end
