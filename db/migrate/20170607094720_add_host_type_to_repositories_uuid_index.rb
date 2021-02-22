# frozen_string_literal: true
class AddHostTypeToRepositoriesUuidIndex < ActiveRecord::Migration[5.0]
  def change
    remove_index :repositories, :uuid
    add_index :repositories, [:host_type, :uuid], unique: true
  end
end
