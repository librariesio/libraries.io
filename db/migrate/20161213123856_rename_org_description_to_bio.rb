# frozen_string_literal: true

class RenameOrgDescriptionToBio < ActiveRecord::Migration[5.0]
  def change
    rename_column :github_organisations, :description, :bio
  end
end
