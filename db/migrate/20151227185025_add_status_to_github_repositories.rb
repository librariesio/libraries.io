# frozen_string_literal: true

class AddStatusToGithubRepositories < ActiveRecord::Migration[5.0]
  def change
    add_column :github_repositories, :status, :string
  end
end
