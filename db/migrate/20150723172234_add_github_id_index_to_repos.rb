# frozen_string_literal: true

class AddGithubIdIndexToRepos < ActiveRecord::Migration[5.0]
  def change
    add_index :github_repositories, :github_id
  end
end
