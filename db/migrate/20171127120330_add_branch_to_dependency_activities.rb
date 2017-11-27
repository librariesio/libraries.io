class AddBranchToDependencyActivities < ActiveRecord::Migration[5.0]
  def change
    add_column :dependency_activities, :branch, :string
  end
end
