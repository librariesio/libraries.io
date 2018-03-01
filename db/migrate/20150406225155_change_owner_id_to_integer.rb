class ChangeOwnerIdToInteger < ActiveRecord::Migration[5.0]
  def up
    change_column :github_repositories, :owner_id, 'integer USING CAST(owner_id AS integer)'
  end

  def down
    change_column :github_repositories, :owner_id, 'varchar USING CAST(owner_id AS varchar)'
  end
end
