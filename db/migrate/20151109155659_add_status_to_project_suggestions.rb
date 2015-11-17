class AddStatusToProjectSuggestions < ActiveRecord::Migration
  def change
    add_column :project_suggestions, :status, :string
  end
end
