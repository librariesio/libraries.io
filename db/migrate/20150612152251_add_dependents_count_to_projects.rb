class AddDependentsCountToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :dependents_count, :integer, default: 0, null: false
  end
end
