# frozen_string_literal: true

class AddSourceNameToGithubRepositories < ActiveRecord::Migration[5.0]
  def change
    add_column :github_repositories, :source_name, :string
  end
end
