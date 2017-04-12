class AddHostToOwnerIndexes < ActiveRecord::Migration[5.0]
  def change
    # drop indexes
    remove_index :repository_users, name: :index_repository_users_on_login
    remove_index :repository_users, :uuid
    remove_index :repository_users, name: :github_users_lower_login
    remove_index :repository_users, name: :index_github_users_on_lowercase_login
    remove_index :repository_organisations, :uuid
    remove_index :repository_organisations, name: :index_github_organisations_on_lowercase_login

    # change uuid to string
    change_column :repository_users, :uuid, :string
    change_column :repository_organisations, :uuid, :string

    # recreate indexes
    add_index :repository_users, [:host_type, :login], unique: true, case_sensitive: false
    add_index :repository_users, [:host_type, :uuid], unique: true

    add_index :repository_organisations, [:host_type, :login], unique: true, case_sensitive: false
    add_index :repository_organisations, [:host_type, :uuid], unique: true
  end
end
