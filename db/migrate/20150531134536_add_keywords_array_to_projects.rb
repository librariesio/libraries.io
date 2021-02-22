# frozen_string_literal: true
class AddKeywordsArrayToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :keywords_array, :string, array: true, default: []
  end
end
