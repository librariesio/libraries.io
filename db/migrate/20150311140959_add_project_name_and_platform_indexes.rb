# frozen_string_literal: true

class AddProjectNameAndPlatformIndexes < ActiveRecord::Migration[5.0]
  def change
    add_index :projects, %i[name platform]
    add_index :versions, :published_at
  end
end
