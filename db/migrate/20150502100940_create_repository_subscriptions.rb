# frozen_string_literal: true
class CreateRepositorySubscriptions < ActiveRecord::Migration[5.0]
  def change
    create_table :repository_subscriptions do |t|
      t.integer :github_repository_id
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
