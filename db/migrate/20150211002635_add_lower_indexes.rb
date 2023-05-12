# frozen_string_literal: true

class AddLowerIndexes < ActiveRecord::Migration[5.0]
  def change
    execute "CREATE INDEX projects_lower_platform ON projects(lower(platform));"
    execute "CREATE INDEX projects_lower_name ON projects(lower(name));"
    execute "CREATE INDEX github_users_lower_login ON github_users(lower(login));"
    add_index :github_contributions, :platform
    add_index :github_contributions, :github_user_id
  end
end
