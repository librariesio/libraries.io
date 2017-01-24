class AddContributionsIndex < ActiveRecord::Migration
  def change
    add_index :github_contributions, [:repository_id, :github_user_id], name: 'index_contributions_on_repository_id_and_user_id'
  end
end
