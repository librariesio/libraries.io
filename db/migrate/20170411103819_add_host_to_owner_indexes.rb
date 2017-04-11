class AddHostToOwnerIndexes < ActiveRecord::Migration[5.0]
  def change
    # drop indexes

      # if index_exists?(:books, :created_at)
      remove_index :repository_users, :login
      remove_index :repository_users, :uuid

      # users
      # t.index "lower((login)::text)", name: "github_users_lower_login", using: :btree
      # t.index "lower((login)::text)", name: "index_github_users_on_lowercase_login", unique: true, using: :btree
      # t.index ["login"], name: "index_repository_users_on_login", using: :btree
      # t.index ["uuid"], name: "index_repository_users_on_uuid", unique: true, using: :btree

      # orgs
      # t.index "lower((login)::text)", name: "index_github_organisations_on_lowercase_login", unique: true, using: :btree
      # t.index ["uuid"], name: "index_repository_organisations_on_uuid", unique: true, using: :btree

    # change uuid to string

    change_column :repository_users, :uuid, :string
    change_column :repository_organisations, :uuid, :string

    # recreate indexes

      # users
      add_index :repository_organisations, [:host_type, :login], unique: true, index: { case_sensitive: false }
      add_index :repository_users, [:host_type, :uuid]

      # orgs
      add_index :repository_organisations, [:host_type, :login], unique: true, index: { case_sensitive: false }
      add_index :repository_organisations, [:host_type, :uuid], unique: true
  end
end
