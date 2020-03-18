# frozen_string_literal: true

class AddMoreIndexToGithubRepositories < ActiveRecord::Migration[5.0]
  def change
    add_index :github_repositories, :full_name
  end
end
