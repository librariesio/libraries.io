# frozen_string_literal: true

class AddIndexToKeywordsArray < ActiveRecord::Migration[5.0]
  def change
    add_index :projects, :keywords_array, using: "gin"
  end
end
