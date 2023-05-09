class AddCoveringIndexOnRepository < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :repositories, %i[rank stargazers_count id], algorithm: :concurrently
  end
end
