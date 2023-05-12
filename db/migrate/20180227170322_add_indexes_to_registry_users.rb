# frozen_string_literal: true

class AddIndexesToRegistryUsers < ActiveRecord::Migration[5.0]
  def change
    add_index :registry_users, %i[platform uuid], unique: true
    add_index :registry_permissions, :project_id
    add_index :registry_permissions, :registry_user_id
  end
end
