# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :uid, null: false
      t.string :nickname, null: false
      t.string :gravatar_id
      t.string :token
      t.string :name
      t.string :blog
      t.string :location
      t.string :email

      t.timestamps
    end

    add_index :users, :nickname, unique: true
  end
end
