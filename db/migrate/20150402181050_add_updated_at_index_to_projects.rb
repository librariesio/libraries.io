# frozen_string_literal: true

class AddUpdatedAtIndexToProjects < ActiveRecord::Migration[5.0]
  def change
    add_index :projects, :updated_at
  end
end
