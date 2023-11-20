# frozen_string_literal: true

class ChangeGithubIdToUuidOnIssues < ActiveRecord::Migration[5.0]
  def change
    rename_column :issues, :github_id, :uuid
    change_column :issues, :uuid, :string
  end
end
