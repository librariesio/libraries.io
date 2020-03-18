# frozen_string_literal: true

class CreateWebHooks < ActiveRecord::Migration[5.0]
  def change
    create_table :web_hooks do |t|
      t.integer :github_repository_id
      t.integer :user_id
      t.string :url
      t.string :last_response
      t.datetime :last_sent_at
      t.index :github_repository_id

      t.timestamps null: false
    end
  end
end
