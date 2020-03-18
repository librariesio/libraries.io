# frozen_string_literal: true

class AddIncludePrereleaseToRepositorySubscriptions < ActiveRecord::Migration[5.0]
  def change
    add_column :repository_subscriptions, :include_prerelease, :boolean, default: true
  end
end
