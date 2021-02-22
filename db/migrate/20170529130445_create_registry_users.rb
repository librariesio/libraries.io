# frozen_string_literal: true
class CreateRegistryUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :registry_users do |t|
      t.string :platform
      t.string :uuid
      t.string :login
      t.string :email
      t.string :name
      t.string :url
    end
  end
end
