class AddForkIndexToRepos < ActiveRecord::Migration
  def change
    add_index :github_repositories, :fork
  end
end
