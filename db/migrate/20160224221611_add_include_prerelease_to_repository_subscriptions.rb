class AddIncludePrereleaseToRepositorySubscriptions < ActiveRecord::Migration
  def change
    add_column :repository_subscriptions, :include_prerelease, :boolean, default: true
  end
end
