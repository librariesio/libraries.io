class AddHookIdToRepositorySubscriptions < ActiveRecord::Migration
  def change
    add_column :repository_subscriptions, :hook_id, :integer
  end
end
