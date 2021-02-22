# frozen_string_literal: true
class CreateAuthTokens < ActiveRecord::Migration[5.0]
  def change
    create_table :auth_tokens do |t|
      t.string :login
      t.string :token

      t.timestamps null: false
    end
  end
end
