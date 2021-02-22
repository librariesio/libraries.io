# frozen_string_literal: true
class AddMoreStatsIndexes < ActiveRecord::Migration[5.0]
  def change
    add_index :github_tags, :created_at
    add_index :github_organisations, :created_at
    add_index :repository_subscriptions, :created_at
    add_index :manifests, :created_at
  end
end
