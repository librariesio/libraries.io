# frozen_string_literal: true
class AddIndexToReadmes < ActiveRecord::Migration[5.0]
  def change
    add_index(:readmes, :created_at)
  end
end
