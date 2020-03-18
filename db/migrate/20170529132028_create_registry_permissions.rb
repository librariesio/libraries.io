# frozen_string_literal: true

class CreateRegistryPermissions < ActiveRecord::Migration[5.0]
  def change
    create_table :registry_permissions do |t|
      t.integer :registry_user_id
      t.integer :project_id
      t.string :kind
    end
  end
end
