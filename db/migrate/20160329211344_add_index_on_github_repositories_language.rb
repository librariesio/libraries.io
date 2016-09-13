class AddIndexOnGithubRepositoriesLanguage < ActiveRecord::Migration
  def change
    execute "CREATE INDEX github_repositories_lower_language ON github_repositories(lower(language));"
  end
end
