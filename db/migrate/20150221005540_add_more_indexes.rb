class AddMoreIndexes < ActiveRecord::Migration[5.0]
  def change
    add_index(:dependencies, :project_id)
    add_index(:github_contributions, :github_repository_id)
    add_index(:github_users, :login)
  end
end
