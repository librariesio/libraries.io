# frozen_string_literal: true
class AddIndexesToGithubRepositories < ActiveRecord::Migration[5.0]
  def change
    add_index :github_repositories, :owner_id
  end
end
