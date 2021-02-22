# frozen_string_literal: true
class AddCreatedAtIndexes < ActiveRecord::Migration[5.0]
  def change
    add_index(:projects, :created_at)
    add_index(:versions, :created_at)
    add_index(:github_repositories, :created_at)
    add_index(:github_users, :created_at)
    add_index(:github_contributions, :created_at)
    add_index(:dependencies, :created_at)
    add_index(:users, :created_at)
    add_index(:subscriptions, :created_at)
  end
end
