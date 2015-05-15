class AddMoreStatsIndexes < ActiveRecord::Migration
  def change
    add_index :github_tags, :created_at
    add_index :github_organisations, :created_at
    add_index :repository_subscriptions, :created_at
    add_index :manifests, :created_at
  end
end
