# frozen_string_literal: true
class RemoveOwnerIdFromRepositories < ActiveRecord::Migration[5.0]
  def change
    remove_column :repositories, :owner_id
  end
end
