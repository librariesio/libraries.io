# frozen_string_literal: true
class DropUserUuidFromIssues < ActiveRecord::Migration[5.0]
  def change
    remove_column :issues, :user_uuid
  end
end
