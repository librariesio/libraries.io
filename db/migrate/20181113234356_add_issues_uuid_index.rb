# frozen_string_literal: true

class AddIssuesUuidIndex < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :issues, %i[repository_id uuid], algorithm: :concurrently
    remove_index :issues, name: "index_issues_on_repository_id"
  end
end
