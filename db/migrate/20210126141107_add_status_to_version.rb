# frozen_string_literal: true

class AddStatusToVersion < ActiveRecord::Migration[5.2]
  def change
    add_column :versions, :status, :string
  end
end
