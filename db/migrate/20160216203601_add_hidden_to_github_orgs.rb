# frozen_string_literal: true
class AddHiddenToGithubOrgs < ActiveRecord::Migration[5.0]
  def change
    add_column :github_organisations, :hidden, :boolean, default: false
    add_index :github_organisations, :hidden
  end
end
