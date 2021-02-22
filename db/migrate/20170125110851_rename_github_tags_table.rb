# frozen_string_literal: true
class RenameGithubTagsTable < ActiveRecord::Migration[5.0]
  def change
    rename_table :github_tags, :tags
  end
end
