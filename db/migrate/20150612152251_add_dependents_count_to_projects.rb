# frozen_string_literal: true

class AddDependentsCountToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :dependents_count, :integer, default: 0, null: false
  end
end
