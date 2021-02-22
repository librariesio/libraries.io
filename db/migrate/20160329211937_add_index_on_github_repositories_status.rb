# frozen_string_literal: true
class AddIndexOnGithubRepositoriesStatus < ActiveRecord::Migration[5.0]
  def change
    add_index :github_repositories, :status
  end
end
