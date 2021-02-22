# frozen_string_literal: true
class AddGithubIdToGithubRepositories < ActiveRecord::Migration[5.0]
  def change
    add_column :github_repositories, :github_id, :integer
  end
end
