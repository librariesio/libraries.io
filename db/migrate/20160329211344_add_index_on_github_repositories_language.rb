# frozen_string_literal: true
class AddIndexOnGithubRepositoriesLanguage < ActiveRecord::Migration[5.0]
  def change
    execute "CREATE INDEX github_repositories_lower_language ON github_repositories(lower(language));"
  end
end
