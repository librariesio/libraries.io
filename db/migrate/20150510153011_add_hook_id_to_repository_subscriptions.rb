class AddHookIdToRepositorySubscriptions < ActiveRecord::Migration[5.0]
  def change
    add_column :repository_subscriptions, :hook_id, :integer
  end
end
