class AddIssuesUuidIndex < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :issues, [:repository_id, :uuid], algorithm: :concurrently
    remove_index :issues, name: "index_issues_on_repository_id"
  end
end
