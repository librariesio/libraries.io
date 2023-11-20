# frozen_string_literal: true

class AddKeywordsToRepositories < ActiveRecord::Migration[5.0]
  def change
    add_column :repositories, :keywords, :string, array: true, default: []
  end
end
