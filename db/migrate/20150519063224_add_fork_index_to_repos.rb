class AddForkIndexToRepos < ActiveRecord::Migration[5.0]
  def change
    add_index :github_repositories, :fork
  end
end
