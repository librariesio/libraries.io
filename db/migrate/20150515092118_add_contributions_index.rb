# frozen_string_literal: true
class AddContributionsIndex < ActiveRecord::Migration[5.0]
  def change
    add_index :github_contributions, [:github_repository_id, :github_user_id], name: 'index_contributions_on_repository_id_and_user_id'
  end
end
