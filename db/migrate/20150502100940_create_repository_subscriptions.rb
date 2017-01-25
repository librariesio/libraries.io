class CreateRepositorySubscriptions < ActiveRecord::Migration
  def change
    create_table :repository_subscriptions do |t|
      t.integer :github_repository_id
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
