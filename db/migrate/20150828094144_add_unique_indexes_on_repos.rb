# frozen_string_literal: true

class AddUniqueIndexesOnRepos < ActiveRecord::Migration[5.0]
  def up
    remove_index :github_repositories, :full_name
    remove_index :github_repositories, :github_id
    add_index :github_repositories, :github_id, unique: true
    execute "CREATE UNIQUE INDEX index_github_repositories_on_lowercase_full_name
             ON github_repositories USING btree (lower(full_name));"
  end

  def down
    execute "DROP INDEX index_github_repositories_on_lowercase_full_name;"
    add_index :github_repositories, :full_name
    add_index :github_repositories, :github_id
  end
end
