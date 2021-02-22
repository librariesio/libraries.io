# frozen_string_literal: true
class AddIndexesToProjects < ActiveRecord::Migration[5.0]
  def change
    add_index :projects, :platform
  end
end
