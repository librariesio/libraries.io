# frozen_string_literal: true
class AddScoreFieldsToProjects < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :score, :integer, default: 0, null: false
    add_column :projects, :score_last_calculated, :datetime
  end
end
