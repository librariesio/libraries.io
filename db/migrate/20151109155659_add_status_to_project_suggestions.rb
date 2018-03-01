class AddStatusToProjectSuggestions < ActiveRecord::Migration[5.0]
  def change
    add_column :project_suggestions, :status, :string
  end
end
