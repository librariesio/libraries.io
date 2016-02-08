class AddProjectIdIndexToSubscriptions < ActiveRecord::Migration
  def change
    add_index :subscriptions, :project_id
  end
end
