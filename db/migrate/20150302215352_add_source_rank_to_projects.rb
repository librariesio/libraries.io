# frozen_string_literal: true

class AddSourceRankToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :rank, :integer, default: 0
  end
end
