# frozen_string_literal: true
class RenameRepositoryUserIdToUuidOnIssues < ActiveRecord::Migration[5.0]
  def change
    rename_column :issues, :repository_user_id, :user_uuid
    add_column :issues, :repository_user_id, :integer
  end
end
