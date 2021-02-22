# frozen_string_literal: true
class ReduceProjectIndexes < ActiveRecord::Migration[5.0]
  def change
    remove_index :projects, name: :projects_lower_name
    remove_index :projects, name: :projects_lower_platform
    remove_index :projects, name: :index_projects_on_name_and_platform
    add_index :projects, [:platform, :name], unique: true
  end
end
