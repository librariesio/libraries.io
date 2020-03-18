# frozen_string_literal: true

class AddRepositoryUserIdToIdentities < ActiveRecord::Migration[5.0]
  def change
    add_column :identities, :repository_user_id, :integer
    add_index :identities, :repository_user_id
  end
end
