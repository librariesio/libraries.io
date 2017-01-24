class AddMoreIndexes < ActiveRecord::Migration
  def change
    add_index(:dependencies, :project_id)
    add_index(:github_contributions, :repository_id)
    add_index(:github_users, :login)
  end
end
