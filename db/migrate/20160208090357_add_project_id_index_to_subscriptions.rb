class AddProjectIdIndexToSubscriptions < ActiveRecord::Migration[5.0]
  def change
    add_index :subscriptions, :project_id
  end
end
