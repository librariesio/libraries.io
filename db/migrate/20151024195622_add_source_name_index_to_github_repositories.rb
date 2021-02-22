# frozen_string_literal: true
class AddSourceNameIndexToGithubRepositories < ActiveRecord::Migration[5.0]
  def change
    add_index :github_repositories, :source_name
  end
end
