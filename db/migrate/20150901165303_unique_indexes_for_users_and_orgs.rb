class UniqueIndexesForUsersAndOrgs < ActiveRecord::Migration[5.0]
  def change
    remove_index :github_users, :github_id
    add_index :github_users, :github_id, :unique => true
    remove_index :github_organisations, :github_id
    add_index :github_organisations, :github_id, :unique => true

    remove_index :github_organisations, :login
    execute "CREATE UNIQUE INDEX index_github_users_on_lowercase_login
             ON github_users USING btree (lower(login));"
    execute "CREATE UNIQUE INDEX index_github_organisations_on_lowercase_login
             ON github_organisations USING btree (lower(login));"
  end
end
