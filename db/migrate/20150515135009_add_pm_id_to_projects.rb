# frozen_string_literal: true
class AddPmIdToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :pm_id, :integer
  end
end
